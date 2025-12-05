function addMissingContours_visual()
    close all; clc;

    %% Parameters
    nContours = 5;
    emptyIdx  = [2 4];            % indices we pretend are missing
    nonEmptyIdx = setdiff(1:nContours, emptyIdx);
    radius = 0.5;
    nPts   = 100;

    %% 1) Define centers A and normals (via A->B)
    A = zeros(nContours, 3);
    B = zeros(nContours, 3);
    normals = zeros(nContours, 3);

    % Centers along y-axis, normals slowly rotating in x–z plane
    for i = 1:nContours
        center = [0, (i-1)*2, 0];           % shift in y
        ang    = (i-1) * pi/12;             % 0,15,30,... deg

        n = [sin(ang), cos(ang), 0];        % unit-ish, will normalize
        n = n / norm(n);

        A(i,:) = center;
        B(i,:) = center + n;                % normal is A->B
        normals(i,:) = n;
    end

    %% 2) Generate contours in planes perpendicular to normals
    allContours = cell(nContours,1);
    for i = 1:nContours
        allContours{i} = makeCircle3D(A(i,:), normals(i,:), radius, nPts);
    end

    %% 3) Build input 'contours' with some missing
    contours = cell(nContours,1);
    for i = nonEmptyIdx
        contours{i} = allContours{i};   % only these exist initially
    end
    % emptyIdx remain [] as missing contours

    %% 4) Visualize ORIGINAL non-empty contours + all normals
    figure('Name','Original data'); hold on; grid on; axis equal; view(3);
    title('Original non-empty contours and all normals');

    cmap = lines(nContours);

    % Plot existing contours
    for i = nonEmptyIdx
        c = contours{i};
        plot3(c(:,1), c(:,2), c(:,3), '-', 'Color', cmap(i,:), 'LineWidth', 1.5);
    end

    % Plot normals (A->B) for all indices
    for i = 1:nContours
        quiver3(A(i,1), A(i,2), A(i,3), ...
                B(i,1)-A(i,1), B(i,2)-A(i,2), B(i,3)-A(i,3), ...
                0, 'k', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        text(A(i,1), A(i,2), A(i,3), sprintf(' %d', i), 'FontSize', 10, 'Color', 'k');
    end
    xlabel X; ylabel Y; zlabel Z;
    legend({'Existing contours','Normals'}, 'Location', 'best');

    %% 5) Run your (fixed) function
    contoursFilled = addMissingContours(A, B, contours);

    %% 6) Visualize TRUE vs RECONSTRUCTED contours
    figure('Name','Filled contours vs ground truth'); hold on; grid on; axis equal; view(3);
    title('Ground truth (dashed) vs filled contours (solid) + normals');

    % Plot ground-truth contours for all indices (dashed)
    for i = 1:nContours
        cTrue = allContours{i};
        plot3(cTrue(:,1), cTrue(:,2), cTrue(:,3), '--', ...
              'Color', cmap(i,:), 'LineWidth', 1.0);
    end

    % Plot all reconstructed contours (for non-empty: they match original)
    for i = 1:nContours
        cRec = contoursFilled{i};
        plot3(cRec(:,1), cRec(:,2), cRec(:,3), '-', ...
              'Color', cmap(i,:), 'LineWidth', iif(ismember(i,emptyIdx), 3.0, 1.5));
    end

    % Normals again for orientation
    for i = 1:nContours
        quiver3(A(i,1), A(i,2), A(i,3), ...
                B(i,1)-A(i,1), B(i,2)-A(i,2), B(i,3)-A(i,3), ...
                0, 'k', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        text(A(i,1), A(i,2), A(i,3), sprintf(' %d', i), 'FontSize', 10, 'Color', 'k');
    end

    % Mark which existing contour was used for each empty index
    for k = 1:numel(emptyIdx)
        idxEmpty = emptyIdx(k);
        nearestExisting = findClosestByIndex(idxEmpty, nonEmptyIdx);
        ce = A(idxEmpty,:);
        text(ce(1), ce(2), ce(3)+0.8, ...
             sprintf('empty %d \leftarrow %d', idxEmpty, nearestExisting), ...
             'Color', cmap(idxEmpty,:), 'FontSize', 10, 'FontWeight', 'bold');
    end

    xlabel X; ylabel Y; zlabel Z;
    legend({'True contours (all indices)', ...
            'Reconstructed (incl. filled empties)', ...
            'Normals'}, 'Location', 'best');
end


%% ===== Helper: build a circle in 3D perpendicular to "normal" =====
function pts = makeCircle3D(center, normal, radius, nPts)
    normal = normal / norm(normal);

    % choose any vector not parallel to the normal
    if abs(dot(normal, [1 0 0])) < 0.9
        v = [1 0 0];
    else
        v = [0 1 0];
    end

    e1 = cross(normal, v); e1 = e1 / norm(e1);
    e2 = cross(normal, e1); % automatically perpendicular to both

    t = linspace(0, 2*pi, nPts).';
    pts = center + radius*(cos(t).*e1 + sin(t).*e2);
end


%% ===== Helper: closest non-empty index by index distance =====
function idx = findClosestByIndex(target, candidates)
    [~, pos] = min(abs(candidates - target));
    idx = candidates(pos);
end


%% ===== Tiny inline "if" helper =====
function out = iif(cond, a, b)
    if cond, out = a; else, out = b; end
end



function contours = addMissingContours(A, B, contours)
    % Substitute missing contours with translated and rotated closest contour

    % For each missing contour, find the closest non-missing contour
    nonEmptyIndices = find(~cellfun('isempty', contours))
    emptyIndices = find(cellfun('isempty', contours))
    disp('empty contours:')
    disp(numel(emptyIndices))

    closestIndices = zeros(size(emptyIndices));
    for iEmpty = 1:numel(emptyIndices)
        emptyIdx = emptyIndices(iEmpty);
        [~, iValid] = min(abs(nonEmptyIndices - emptyIdx));
        closestIndices(iEmpty) = nonEmptyIndices(iValid);
    end

    % For each missing contour, we need to get the translation and rotation
    for iEmpty = 1:numel(emptyIndices)
        AEmpty = A(emptyIndices(iEmpty), :);
        BEmpty = B(emptyIndices(iEmpty), :);
        NormalVectorEmpty = (BEmpty - AEmpty)/norm(BEmpty - AEmpty);

        AClosest = A(closestIndices(iEmpty), :);
        BClosest = B(closestIndices(iEmpty), :);
        NormalVectorClosest = (BClosest - AClosest)/norm(BClosest - AClosest);

        % Calculate rotation matrix from closest to empty
        cosTheta = dot(NormalVectorClosest, NormalVectorEmpty)/(norm(NormalVectorClosest)*norm(NormalVectorEmpty));
        sinTheta = norm(cross(NormalVectorClosest, NormalVectorEmpty))/(norm(NormalVectorClosest)*norm(NormalVectorEmpty));

        C = cross(NormalVectorClosest, NormalVectorEmpty);
        u1 = C(1)/norm(C);
        u2 = C(2)/norm(C);
        u3 = C(3)/norm(C);

        R = [cosTheta + u1^2 * (1 - cosTheta)      u1 * u2 * (1 - cosTheta) - u3 * sinTheta    u1 * u3 * (1 - cosTheta) + u2 * sinTheta;
            u2 * u1 * (1 - cosTheta) + u3 * sinTheta    cosTheta + u2^2 * (1 - cosTheta)    u2 * u3 * (1 - cosTheta) - u1 * sinTheta;
            u3 * u1 * (1 - cosTheta) - u2 * sinTheta    u3 * u2 * (1 - cosTheta) + u1 * sinTheta    cosTheta + u3^2 * (1 - cosTheta)];

        % Apply rotation and translation to the closest contour
        contourClosest = contours{closestIndices(iEmpty)};
        contourTranslated = (contourClosest - AClosest) * R' + AEmpty;  % R' is the inverse rotation
        contours{emptyIndices(iEmpty)} = contourTranslated;
    end
end


