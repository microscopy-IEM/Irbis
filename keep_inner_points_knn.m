% projected = pointsRescaled(:, [1, 3]) - [50, 50]
% [theta, r] = cart2pol(projected(:, 1), projected(:, 2));


function [keepMask, votes] = keep_inner_points_knn(P, c, nsamp, K, q, voteThresh)
    % P = P3D(:, [1, 3]) - [50, 50]
% [theta, r] = cart2pol(projected(:, 1), projected(:, 2));    
    % KEEP_INNER_POINTS_KNN
    % Uses K nearest points in angle (around each query angle) to set an inner-radius quantile.
    % P : Nx2 points
    % c : [cx cy] center
    % nsamp : number of query angles around circle (e.g., 72 -> every 5°)
    % K : number of nearest-by-angle points per query (e.g., 7–11)
    % q : lower quantile (e.g., 0.33)
    % voteThresh : how many query angles must vote 'inner' to keep a point

    if nargin<3 || isempty(nsamp), nsamp = 72; end
    if nargin<4 || isempty(K),     K     = 9;  end
    if nargin<5 || isempty(q),     q     = 0.33; end
    if nargin<6 || isempty(voteThresh), voteThresh = 1; end

    X = P(:,1) - c(1);
    Y = P(:,2) - c(2);
    [theta, r] = cart2pol(X, Y);

    theta_q = linspace(-pi, pi, nsamp+1).'; theta_q(end) = [];
    votes = zeros(size(r));

    for k = 1:numel(theta_q)
        t0 = theta_q(k);
        % circular angular distance
        d = abs(atan2(sin(theta - t0), cos(theta - t0)));
        [~, ord] = sort(d);
        pick = ord(1:min(K, numel(ord)));
        rq = quantile(r(pick), q);
        % vote for points within a small angular neighborhood and with r <= rq
        % (Use K as the implicit neighborhood)
        inner = false(size(r));
        inner(pick) = r(pick) <= rq;
        votes(inner) = votes(inner) + 1;
    end

    keepMask = votes >= voteThresh;
end
