classdef ObjectRegistration
%ObjectRegistration  Time-series registration of 3-D objects.
%
%   matcher = ObjectRegistration(... 'distanceThreshold',0.8, ...
%                                'weights',[1 0.2 0.3]);
%
%   tOut = matcher.match(tIn,timePoints)
%
% Each input table must now contain:
%   • Mesh     – mesh struct with .vertices (n×3 double)
%   • volume   – scalar double  (pre-computed object volume)
%   • nextTPid – double (will be overwritten)
%   • groupId  – double (will be overwritten/extended)
% -------------------------------------------------------------------------

    properties
        distanceThreshold double = 0.5          % composite distance (µm)
        weights           (1,3)  double = [1 0.1 0.5]   % centre | volume | shape
    end

    methods
        % ----- constructor --------------------------------------------------
        function obj = ObjectRegistration(varargin)
            p = inputParser;
            % this way of adding parameters allows me to used them in a named way and any order
            addParameter(p,'distanceThreshold',obj.distanceThreshold,@isscalar)
            addParameter(p,'weights',          obj.weights,@(x)numel(x)==3)
            parse(p,varargin{:});
            obj.distanceThreshold = p.Results.distanceThreshold;
            obj.weights           = p.Results.weights;
        end

        % ----- public API ---------------------------------------------------
        function [tOut,info] = match(obj,tIn,timePoints)
            if nargin<3
                timePoints = 1:numel(tIn);
            end
            N        = numel(timePoints);
            tOut     = tIn;
            nextId   = 1;

            % --------- pass 1 – pair objects --------------------------------
            for k = 1:N-1
                A = tIn{timePoints(k)};
                B = tIn{timePoints(k+1)};

                featA = obj.meshFeatures(A);     % nA×7
                featB = obj.meshFeatures(B);     % nB×7
                D     = obj.composeDistance(featA,featB);

                [dMin,idxB] = min(D,[],2);
                valid       = dMin <= obj.distanceThreshold;

                A.nextTPid(:) = 0;
                A.groupId (:) = 0;
                A.nextTPid(valid) = str2double(B.Properties.RowNames(idxB(valid)));

                tOut{timePoints(k)}   = A;
                tOut{timePoints(k+1)} = B;       % B unchanged for now
            end

            % --------- pass 2 – propagate group ids -------------------------
            for k = 1:N-1
                A = tOut{timePoints(k)};
                B = tOut{timePoints(k+1)};

                for r = 1:height(A)
                    nxt = A.nextTPid(r);
                    if nxt==0
                        continue
                    end

                    if A.groupId(r)==0
                        gid          = nextId;   nextId = nextId+1;
                        A.groupId(r) = gid;
                        B(num2str(nxt),:).groupId = gid;
                    else
                        gid = A.groupId(r);
                        B(num2str(nxt),:).groupId = gid;
                    end
                end
                tOut{timePoints(k)}   = A;
                tOut{timePoints(k+1)} = B;
            end

            if nargout>1
                info = struct('weights',obj.weights);
            end
        end
    end

    % ============= helpers (hidden) =========================================
    methods (Access=private)
        function F = meshFeatures(~,tbl)
            % Return [centre(1×3)  volume  shape(1×3)] for every row.
            if ~any(strcmpi(tbl.Properties.VariableNames,'volume'))
                error('ObjectRegistration:NoVolumeColumn', ...
                      'Expected a ''volume'' column in the input table.')
            end

            n = height(tbl);
            F = zeros(n,7);

            % detect exact column name once
            volCol = tbl.(tbl.Properties.VariableNames{ ...
                             find(strcmpi(tbl.Properties.VariableNames,'volume'),1)});

            for i = 1:n
                msh = tbl.Mesh{i};
                if isempty(msh),  continue, end
                V   = msh.vertices;

                ctr = mean(V,1,'omitnan');      % centre (µm)
                vol = volCol(i);                % pre-computed volume (µm³)
                rad = shapeRadii(V);            % simple shape descriptor

                F(i,:) = [ctr vol rad.'];
            end

            % ---- local helper ---------------------------------------------
            function r = shapeRadii(P)
                E = eig(cov(double(P)));
                r = sqrt(max(E,0));
            end
        end

        function D = composeDistance(obj,A,B)
            dCtr = pdist2(A(:,1:3),B(:,1:3));          % centre
            dVol = abs(A(:,4) - B(:,4).');             % volume
            dShp = pdist2(A(:,5:7),B(:,5:7));          % shape
            w    = obj.weights;
            D    = w(1)*dCtr + w(2)*dVol + w(3)*dShp;
        end
    end
end
