% super important finding - the order of vertexIds in faces determines the orientation of the face
% based on the right-hand rule

function [vertices, faces] = createCylinderObject(nSides, nLayers, radius, height, numberingType, nBaseLayers)
    % createCylinderObject
    %
    % Creates a watertight cylindrical triangular mesh with:
    %   - nSides vertices around circumference
    %   - nLayers rings along cylinder height
    %   - nBaseLayers additional concentric rings inside each base
    %
    % numberingType == 0  -> zero-based face indexing
    % otherwise           -> one-based face indexing
    %
    % The generated mesh is watertight and uses consistent face winding.

    arguments
        nSides (1,1) {mustBeInteger, mustBeGreaterThanOrEqual(nSides, 3)}
        nLayers (1,1) {mustBeInteger, mustBeGreaterThanOrEqual(nLayers, 2)}
        radius (1,1) {mustBePositive}
        height (1,1) {mustBePositive}
        numberingType (1,1) {mustBeNumeric}
        nBaseLayers (1,1) {mustBeInteger, mustBeGreaterThanOrEqual(nBaseLayers,0)} = 0
    end

    % angular positions
    theta = linspace(0, 2*pi, nSides+1);
    theta(end) = [];

    % helper for creating a ring
        function ringVerts = makeRing(r, z)
            ringVerts = [r*cos(theta(:)), r*sin(theta(:)), z*ones(nSides,1)];
        end

    % ------------------------------------------------------------------------
    % vertex generation
    % vertex layout:
    %   1                    : bottom center
    %   bottom inner rings   : from inner to outer
    %   side rings           : from bottom to top (outer radius only)
    %   top inner rings      : from outer-inner interface inward
    %   last                 : top center
    % ------------------------------------------------------------------------


    nVertices = 2 + nSides * (nLayers + 2*nBaseLayers);
    nFaces    = 2 * nSides * (nLayers + 2*nBaseLayers);
    vertices = zeros(nVertices,3);
    faces = zeros(nFaces,3);

    v = 1;
    % bottom center
    idCenterBottom = v;
    vertices(v,:) = [0 0 0];
    v = v + 1;

    % bottom interior rings (exclude outer boundary ring, because that is shared with side ring 1)
    bottomInnerRingIds = cell(nBaseLayers,1);
    for k = 1:nBaseLayers
        r = radius * k / (nBaseLayers + 1);
        ids = v:(v+nSides-1);
        bottomInnerRingIds{k} = ids;
        vertices(ids,:) = makeRing(r, 0);
        v = v + nSides;
    end

    % side rings, including bottom and top boundary rings
    zLayers = linspace(0, height, nLayers);
    sideRingIds = cell(nLayers,1);
    for l = 1:nLayers
        ids = v:(v+nSides-1);
        sideRingIds{l} = ids;
        vertices(ids,:) = makeRing(radius, zLayers(l));
        v = v + nSides;
    end

    % top interior rings (exclude outer boundary ring, because that is shared with side ring end)
    topInnerRingIds = cell(nBaseLayers,1);
    for k = nBaseLayers:-1:1
        r = radius * k / (nBaseLayers + 1);
        ids = v:(v+nSides-1);
        topInnerRingIds{nBaseLayers-k+1} = ids;
        vertices(ids,:) = makeRing(r, height);
        v = v + nSides;
    end

    % top center
    idCenterTop = v;
    vertices(v,:) = [0 0 height];

    % ------------------------------------------------------------------------
    % face generation

    f = 1;

    % bottom cap
    % We construct rings from center outward:
    %   center -> bottomInnerRingIds{1} -> ... -> bottomInnerRingIds{end} -> sideRingIds{1}


    if nBaseLayers == 0
        outerRing = sideRingIds{1};
        for i = 1:nSides
            i2 = mod(i, nSides) + 1;
            faces(f,:) = [idCenterBottom, outerRing(i2), outerRing(i)];
            f = f + 1;
        end
    else
        % center to first inner ring
        ring1 = bottomInnerRingIds{1};
        for i = 1:nSides
            i2 = mod(i, nSides) + 1;
            faces(f,:) = [idCenterBottom, ring1(i2), ring1(i)];
            f = f + 1;
        end

        % between interior rings
        for k = 1:(nBaseLayers-1)
            ringIn  = bottomInnerRingIds{k};
            ringOut = bottomInnerRingIds{k+1};
            for i = 1:nSides
                i2 = mod(i, nSides) + 1;
                faces(f,:) = [ringIn(i),  ringOut(i2), ringOut(i)];
                f = f + 1;
                faces(f,:) = [ringIn(i),  ringIn(i2),  ringOut(i2)];
                f = f + 1;
            end
        end

        % last interior ring to outer boundary ring shared with side
        ringIn  = bottomInnerRingIds{end};
        ringOut = sideRingIds{1};
        for i = 1:nSides
            i2 = mod(i, nSides) + 1;
            faces(f,:) = [ringIn(i),  ringOut(i2), ringOut(i)];
            f = f + 1;
            faces(f,:) = [ringIn(i),  ringIn(i2),  ringOut(i2)];
            f = f + 1;
        end
    end

    % side surface

    for l = 1:(nLayers-1)
        ringBottom = sideRingIds{l};
        ringTop    = sideRingIds{l+1};
        for i = 1:nSides
            i2 = mod(i, nSides) + 1;
            faces(f,:) = [ringBottom(i), ringBottom(i2), ringTop(i2)];
            f = f + 1;
            faces(f,:) = [ringBottom(i), ringTop(i2),    ringTop(i)];
            f = f + 1;
        end
    end

    % top cap
    % We construct rings from outer shared boundary inward:
    %   sideRingIds{end} -> topInnerRingIds{1} -> ... -> topInnerRingIds{end} -> center


    if nBaseLayers == 0
        outerRing = sideRingIds{end};
        for i = 1:nSides
            i2 = mod(i, nSides) + 1;
            faces(f,:) = [idCenterTop, outerRing(i), outerRing(i2)];
            f = f + 1;
        end
    else
        % outer boundary ring to first interior ring
        ringOut = sideRingIds{end};
        ringIn  = topInnerRingIds{1};
        for i = 1:nSides
            i2 = mod(i, nSides) + 1;
            faces(f,:) = [ringOut(i), ringOut(i2), ringIn(i2)];
            f = f + 1;
            faces(f,:) = [ringOut(i), ringIn(i2),  ringIn(i)];
            f = f + 1;
        end

        % between top interior rings
        for k = 1:(nBaseLayers-1)
            ringOut = topInnerRingIds{k};
            ringIn  = topInnerRingIds{k+1};
            for i = 1:nSides
                i2 = mod(i, nSides) + 1;
                faces(f,:) = [ringOut(i), ringOut(i2), ringIn(i2)];
                f = f + 1;
                faces(f,:) = [ringOut(i), ringIn(i2),  ringIn(i)];
                f = f + 1;
            end
        end

        % last interior ring to center
        ringLast = topInnerRingIds{end};
        for i = 1:nSides
            i2 = mod(i, nSides) + 1;
            faces(f,:) = [idCenterTop, ringLast(i), ringLast(i2)];
            f = f + 1;
        end
    end

    vertices(:,3) = vertices(:,3) - height/2;
    vertices(:,[1 2 3]) = vertices(:,[1 3 2]);
    vertices(:,2) = -vertices(:,2);

    % convert indexing if requested
    if isequal(numberingType, 0)
        faces = faces - 1;
    end

end