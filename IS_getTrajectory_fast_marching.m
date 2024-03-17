% IS created 230922

function dendrite_trajectory = IS_getTrajectory_fast_marching(wf_singlezstack,start_point,end_point,varargin)

    % start_point = [79;1;13]
    % end_point = [466;559;16]

    clear options;
    options.nb_iter_max = Inf;
    options.end_points = end_point;

    if nargin == 4
        options.constraint_map = varargin{1};
        % disp(['varargin size: ' num2str(size(varargin{1}))])
    end

    [D,S,Q] = perform_fast_marching(wf_singlezstack,start_point,options);

    dendrite_trajectory = compute_geodesic(D,end_point);
end