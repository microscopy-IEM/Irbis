function peaks = mosaicPeakFinder(app,refIm,w,pth)
        
            orig = mat2gray(refIm);
            
            %% Part I
            
            % correlation length of camera noise (usu. set to unity)
            lambdan = 1;
            
            % some often used quantities
            idx = -w:1:w;     % index vector
            dm = 2*w+1;         % diameter
            im = repmat(idx',1,dm);
            jm = repmat(idx,dm,1);
            imjm2 = im.^2+jm.^2;
            siz = size(orig);   % image size
            
            
            z = false(siz);
            z(w:siz(1)-w,w:siz(2)-w) = 1;
            %====================================================================== 
            % STEP 1: Image restoration
            %====================================================================== 
            
            % build kernel K for background extraction and noise removal
            % (eq. [4])
            B = sum(exp(-(idx.^2/(4*lambdan^2))));
            B = B^2;
            K0 = 1/B*sum(exp(-(idx.^2/(2*lambdan^2))))^2-(B/(dm^2));
            K = (exp(-(imjm2/(4*lambdan^2)))/B-(1/(dm^2)))/K0;
            
            % apply convolution filter
            % filtered = conv2(orig,K,'same');
            % filtered = conv2(orig,K,'valid');
            
            % SK: conv2 was repleced by imfilter to treat the edge problem
            % filtered = imfilter(orig,K,'replicate');
            filtered = imfilter(orig,K,'symmetric');
            
            
            %====================================================================== 
            % STEP 2: Locating particles
            %====================================================================== 
            
            % determining upper pth-th percentile of intensity values
            pth = 0.01*pth;
            [cnts,bins] = imhist(filtered(z));
            l = length(cnts);
            k = 1;
            while sum(cnts(l-k:l))/sum(cnts) < pth
                k = k + 1;
            end
            thresh = bins(l-k+1);
            
            % generate circular mask of radius w
            mask = zeros(dm,dm);
            mask(imjm2 <= w*w) = 1;
            
            % identify individual particles as local maxima in a
            % w-neighborhood that are larger than thresh
            dil = imdilate(filtered,mask);
            [Rp,Cp] = find((dil-filtered)==0);
%             particles = zeros(siz);
            V = find(filtered(sub2ind(siz,Rp,Cp))>thresh);
            % particle coordinates R (rows) C (columns)
            R = Rp(V);
            C = Cp(V);
%             particles(sub2ind(siz,R,C)) = 1;
            npart = length(R);
            
            %====================================================================== 
            % STEP 3: Refining location estimates
            %====================================================================== 
            
            % zero and second order intensity moments of all particles
            m0 = zeros(npart,1);
            m2 = zeros(npart,1);
            
            % for each particle: compute zero and second order moments
            % and position corrections epsx, epsy
            nlim = 5;
            
            for ipart=1:npart
                epsx = 1; epsy = 1;
                count = 0;
                while or(abs(epsx)>0.5,abs(epsy)>0.5)
                  
	                % lower and upper index bounds for all particle neighborhoods
	                % in local coordinates. Recalculate after every change in R,C
	                li = 1-(R-w-saturate(app,R-w,1,siz(1)));
	                lj = 1-(C-w-saturate(app,C-w,1,siz(2)));
	                ui = dm-(R+w-saturate(app,R+w,1,siz(1)));
	                uj = dm-(C+w-saturate(app,C+w,1,siz(2)));
	                % masked image part containing the particle
	                Aij = filtered(R(ipart)+li(ipart)-w-1:R(ipart)+ui(ipart)-w-1,...
	                    C(ipart)+lj(ipart)-w-1:C(ipart)+uj(ipart)-w-1).* ...
	                    mask(li(ipart):ui(ipart),lj(ipart):uj(ipart));
	                % moments
	                m0(ipart) = sum(sum(Aij));    % eq. [6]
	                % eq. [7]
	                m2(ipart) = sum(sum(imjm2(li(ipart):ui(ipart),lj(ipart):uj(ipart))...
	                    .*Aij))/m0(ipart); 
	                % position correction
	                epsx = sum(sum(im(li(ipart):ui(ipart),lj(ipart):uj(ipart)).*Aij))/m0(ipart);
                    
                    
	                epsy = sum(idx(lj(ipart):uj(ipart)).*sum(Aij))/m0(ipart);
	                % if correction is > 0.5, move candidate location
	                    
                    if abs(epsx)>0.5
	                        
                            R(ipart) = R(ipart)+sign(epsx);
        
                    elseif abs(epsy)>0.5
	                        
                            C(ipart) = C(ipart)+sign(epsy);
                    end
                      count = count + 1;
                        
                    if count >= nlim
                           break;
                    end
                
                end
                % correct positions (eq. [5])
                R(ipart) = R(ipart)+epsx;
                C(ipart) = C(ipart)+epsy;
            end
            
            peaks = [C R];
end


function result = saturate(~,in,min,max)
                        
            result = in;
            result(in>max)=max;
            result(in<min)=min;

end