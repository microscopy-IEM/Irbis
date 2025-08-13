classdef test_planesPreregistration < matlab.unittest.TestCase
    properties
        PreregFcn  % @(stack) -> [regStack, driftCell]
    end

    methods (TestClassSetup)
        function setFunctionHandle(tc)
            % tc.PreregFcn = @registerPlanesDefault;
            ch = 1;
            % runHeadless = true;  % run without GUI
            % tc.PreregFcn = @(zstack) preRegisterPlanesFcn(zstack, ch, runHeadless);
            registrationObject = planeRegistration;
            tc.PreregFcn = @(zstack) registrationObject.runGUI(zstack, ch);
        end
    end

    methods (Test)
        function noShift_returnsSameVolume_noCrop(tc)
            sz=[64 60 40]; radius=12; center=round(sz/2); T=3;
            shifts=zeros(T,3);

            [stack,sphereMask]=tc.makeShiftedStack(sz,radius,center,shifts);
            size(stack)
            [regStack,driftCell]=tc.PreregFcn(stack); drift=tc.driftCellToMat(driftCell);

            [cropStart,~]=tc.expectedCropFromShifts(sz,shifts);
            expDrift = tc.expectedDriftFromShiftsAndCrop(shifts,cropStart);

            tc.verifyEqual(size(regStack),[sz T]);
            tc.verifyEqual(drift,expDrift);               % <-- uses shift+crop
            tc.verifyEqual(double(regStack),stack);
            tc.verifyEqual(double(regStack(:,:,:,1)),sphereMask);
        end

        function pureIntegerTranslations_correctDriftAndCrop_minusShift(tc)
            sz=[80 76 50]; radius=14; center=[40 38 25];
            % shifts=[ 0  0  0;
            %          3 -4  2;
            %         -5  6 -1;
            %          2  2  0 ];
            shifts=[ 0  0  0;
                     0  -5  0];

            [stack,~]=tc.makeShiftedStack(sz,radius,center,shifts);
            [regStack,driftCell]=tc.PreregFcn(stack); drift=tc.driftCellToMat(driftCell);

            visualShifts = shifts(:, [2 1 3]);
            [cropStart,cropEnd]=tc.expectedCropFromShifts(sz,visualShifts);
            expDrift = tc.expectedDriftFromShiftsAndCrop(shifts,cropStart(:,[2 1 3]));
            tc.verifyEqual(drift,expDrift,'AbsTol',0);     % integers

            expectedSize=[cropEnd-cropStart+1, size(stack,4)];
            tc.verifyEqual(size(regStack),expectedSize);

            ref=tc.cropVolume(stack(:,:,:,1),cropStart,cropEnd);
            for t=1:size(stack,4)
                tc.verifyEqual(double(regStack(:,:,:,t)),ref);
            end
        end

        function pureIntegerTranslations_correctDriftAndCrop_plusShift(tc)
            sz=[80 76 50]; radius=14; center=[40 38 25];
            % shifts=[ 0  0  0;
            %          3 -4  2;
            %         -5  6 -1;
            %          2  2  0 ];
            shifts=[ 0  0  0;
                     0  5  0];

            [stack,~]=tc.makeShiftedStack(sz,radius,center,shifts);
            [regStack,driftCell]=tc.PreregFcn(stack); drift=tc.driftCellToMat(driftCell);

            visualShifts = shifts(:, [2 1 3]);
            [cropStart,cropEnd]=tc.expectedCropFromShifts(sz,visualShifts);
            expDrift = tc.expectedDriftFromShiftsAndCrop(shifts,cropStart(:,[2 1 3]));
            tc.verifyEqual(drift,expDrift,'AbsTol',0);     % integers

            expectedSize=[cropEnd-cropStart+1, size(stack,4)];
            tc.verifyEqual(size(regStack),expectedSize);

            ref=tc.cropVolume(stack(:,:,:,1),cropStart,cropEnd);
            for t=1:size(stack,4)
                tc.verifyEqual(double(regStack(:,:,:,t)),ref);
            end
        end

        function pureIntegerTranslations_correctDriftAndCrop_bothPlusShift(tc)
            sz=[80 76 50]; radius=14; center=[40 38 25];
            % shifts=[ 0  0  0;
            %          3 -4  2;
            %         -5  6 -1;
            %          2  2  0 ];
            shifts=[ 0  0  0;
                     5  5  0];

            [stack,~]=tc.makeShiftedStack(sz,radius,center,shifts);
            assignin("base", "stack", stack)
            [regStack,driftCell]=tc.PreregFcn(stack); drift=tc.driftCellToMat(driftCell);

            visualShifts = shifts(:, [2 1 3]);
            [cropStart,cropEnd]=tc.expectedCropFromShifts(sz,visualShifts);
            expDrift = tc.expectedDriftFromShiftsAndCrop(shifts,cropStart(:,[2 1 3]));
            tc.verifyEqual(drift,expDrift,'AbsTol',0);     % integers

            expectedSize=[cropEnd-cropStart+1, size(stack,4)];
            tc.verifyEqual(size(regStack),expectedSize);

            ref=tc.cropVolume(stack(:,:,:,1),cropStart,cropEnd);
            % figure
            % imshow(max(ref, [], 3))
            for t=1:size(stack,4)
                % figure
                % imshow(max(regStack(:,:,:,t), [], 3))
                tc.verifyEqual(double(regStack(:,:,:,t)),ref);
            end
        end

        function pureIntegerTranslations_correctDriftAndCrop(tc)
            sz=[80 76 50]; radius=14; center=[40 38 25];
            % shifts=[ 0  0  0;
            %          3 -4  2;
            %         -5  6 -1;
            %          2  2  0 ];
            shifts=[ 0  0  0;
                     3 -4  0;
                    -5  6 0;
                     2  2  0 ];

            [stack,~]=tc.makeShiftedStack(sz,radius,center,shifts);
            assignin("base", "stack", stack)
            [regStack,driftCell]=tc.PreregFcn(stack); drift=tc.driftCellToMat(driftCell);

            visualShifts = shifts(:, [2 1 3]);
            [cropStart,cropEnd]=tc.expectedCropFromShifts(sz,visualShifts);
            expDrift = tc.expectedDriftFromShiftsAndCrop(shifts,cropStart(:,[2 1 3]));
            tc.verifyEqual(drift,expDrift,'AbsTol',0);     % integers

            expectedSize=[cropEnd-cropStart+1, size(stack,4)];
            tc.verifyEqual(size(regStack),expectedSize);

            ref=tc.cropVolume(stack(:,:,:,1),cropStart,cropEnd);
            for t=1:size(stack,4)
                tc.verifyEqual(double(regStack(:,:,:,t)),ref);
            end
        end

        function mixedPositiveNegativeShifts_variedCrop(tc)
            sz=[72 74 48]; radius=13; center=[36 37 24];
            shifts=[ 0  0  0;
                     7  0 -3;
                    -4 -5  1 ];

            [stack,~]=tc.makeShiftedStack(sz,radius,center,shifts);
            [regStack,driftCell]=tc.PreregFcn(stack); drift=tc.driftCellToMat(driftCell);

            visualShifts = shifts(:, [2 1 3]);
            [cropStart,cropEnd]=tc.expectedCropFromShifts(sz,visualShifts);
            expDrift = tc.expectedDriftFromShiftsAndCrop(shifts,cropStart(:,[2 1 3]));
            tc.verifyEqual(drift,expDrift);

            tc.verifyEqual(size(regStack,1),cropEnd(1)-cropStart(1)+1);
            tc.verifyEqual(size(regStack,2),cropEnd(2)-cropStart(2)+1);
            tc.verifyEqual(size(regStack,3),cropEnd(3)-cropStart(3)+1);

            ref=tc.cropVolume(stack(:,:,:,1),cropStart,cropEnd);
            for t=1:size(stack,4)
                % figure
                % imshow(max(regStack(:,:,:,t), [], 3))
                tc.verifyEqual(double(regStack(:,:,:,t)),ref);
            end
        end

        function smallNoise_robustAlignment(tc)
            rng(42);
            sz=[64 64 40]; radius=12; center=[32 32 20];
            shifts=[0 0 0; 4 -3 2; -2 5 0];

            [stack,~]=tc.makeShiftedStack(sz,radius,center,shifts);
            stack = stack + 0.02*randn(size(stack));
            [regStack,driftCell]=tc.PreregFcn(stack); drift=tc.driftCellToMat(driftCell);

            visualShifts = shifts(:, [2 1 3]);
            [cropStart,cropEnd]=tc.expectedCropFromShifts(sz,visualShifts);
            expDrift = tc.expectedDriftFromShiftsAndCrop(shifts,cropStart(:,[2 1 3]));

            % Allow rounding if your method outputs doubles
            tc.verifyEqual(round(drift),round(expDrift));

            ref=tc.cropVolume(stack(:,:,:,1),cropStart,cropEnd);
            for t=1:size(stack,4)
                c=tc.volCorr(ref,double(regStack(:,:,:,t)));
                tc.verifyGreaterThan(c,0.97);
            end
        end
    end

    %% ===== Helpers =====
    methods (Access=private)
        function M = driftCellToMat(~, driftCell)
            T=numel(driftCell); M=nan(T,3);
            for t=1:T, v=driftCell{t}; M(t,:)=double(v(:)).'; end
        end

        function [stack, sphereVol] = makeShiftedStack(tc, sz, radius, center, shifts)
            sphereVol=tc.sphereVolume(sz,radius,center);
            T=size(shifts,1); stack=zeros([sz T],'double');
            for t=1:T
                dx=shifts(t,1); dy=shifts(t,2); dz=shifts(t,3);
                stack(:,:,:,t)=tc.placeVolumeWithShift(sphereVol,dx,dy,dz);
                % figure
                % imshow(max(stack(:,:,:,t), [], 3))
            end
        end

        function vol=sphereVolume(~,sz,radius,center)
            [X,Y,Z]=ndgrid(1:sz(1),1:sz(2),1:sz(3));
            vol=double((X-center(1)).^2 + (Y-center(2)).^2 + (Z-center(3)).^2 <= radius^2);
        end

        function shifted=placeVolumeWithShift(~,vol,dx,dy,dz)
            % to have it oriented in accordance with the visual aspect, x represents columns (2nd dim) and y rows (1st dim)
            sz=size(vol); shifted=zeros(sz,'like',vol);
            srcY=max(1,1+dy):min(sz(1),sz(1)+dy);
            srcX=max(1,1+dx):min(sz(2),sz(2)+dx);
            srcZ=max(1,1+dz):min(sz(3),sz(3)+dz);
            if isempty(srcX) || isempty(srcY) || isempty(srcZ), return; end
            shifted(srcY-dy,srcX-dx, srcZ-dz)=vol(srcY,srcX,srcZ);
            shifted(srcY-dy,srcX-dx, srcZ)=vol(srcY,srcX,srcZ);  % for now, do not shift z
        end

        function [cropStart,cropEnd]=expectedCropFromShifts(~,sz,shifts)
            maxS=max(shifts,[],1); minS=min(shifts,[],1);
            cropStart = [1 1 1] + max([0 0 0], maxS);      % lower bound shift
            cropEnd   = sz - max([0 0 0], -minS);          % upper bound shift

            cropStart(3) = 1; % Z-axis is not shifted so far
            cropEnd(3)   = sz(3); % Z-axis is not shifted so far
        end

        function expDrift=expectedDriftFromShiftsAndCrop(~,shifts,cropStart)
            originOffset = cropStart - 1;                  % per-axis
            expDrift = shifts - originOffset;             % apply align + crop origin
            expDrift(:, 3) = 0; % Z-axis is not shifted so far
        end

        function sub=cropVolume(~,vol,cropStart,cropEnd)
            sub=vol(cropStart(1):cropEnd(1),cropStart(2):cropEnd(2),cropStart(3):cropEnd(3));
        end

        function c=volCorr(~,A,B)
            a=A(:)-mean(A(:)); b=B(:)-mean(B(:));
            d=norm(a)*norm(b); if d==0, c=1; else, c=(a.'*b)/d; end
        end
    end
end
