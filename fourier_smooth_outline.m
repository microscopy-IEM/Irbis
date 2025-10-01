function [xy_smooth, coeffs] = fourier_smooth_outline(P, M, K)
% FOURIER_SMOOTH_OUTLINE  Smooth a closed 2D outline with Fourier descriptors.
% P : Nx2 unordered points (approximate closed boundary)
% M : number of uniform samples along the boundary (e.g., 256)
% K : number of retained harmonics (e.g., 10–30). 0 keeps only DC (centroid).
% xy_smooth : Mx2 smoothed coordinates in original scale
% coeffs : struct with FFT coefficients (can be reused across rings)

    if nargin<2, M = 256; end
    if nargin<3, K = 20;  end

    % ---- 1) Order P around center and resample uniformly by arc length
    P = P(~any(isnan(P),2),:); % clean
    c = mean(P,1);             % centroid (works fine here)
    ang = atan2(P(:,2)-c(2), P(:,1)-c(1));
    [ang, idx] = sort(ang);
    Q = P(idx,:);

    % Close the loop and do arc-length parameterization
    Q = unique(Q, 'rows', 'stable');
    if ~isequal(Q(1,:), Q(end,:)), Q = [Q; Q(1,:)]; end
    seg = vecnorm(diff(Q,1,1), 2, 2);
    s = [0; cumsum(seg)];
    L = s(end);

    % Uniform samples along 0..L
    su = linspace(0, L, M+1).'; su(end) = [];
    x = interp1(s, Q(:,1), su, 'linear');
    y = interp1(s, Q(:,2), su, 'linear');

    % ---- 2) Fourier descriptors on complex signal z(t)
    z = x + 1i*y;                   % M samples, periodic
    Z = fft(z)/M;                   % Fourier coeffs (0..M-1), normalized

    % ---- 3) Truncate to ±K harmonics (low-pass the shape)
    Zf = zeros(size(Z));
    % DC term:
    Zf(1) = Z(1);
    % Positive frequencies 1..K and their conjugate counterparts:
    for k = 1:K
        Zf(1+k)     = Z(1+k);
        Zf(end+1-k) = Z(end+1-k);   % negative frequency
    end

    % ---- 4) Reconstruct
    z_s = ifft(Zf*M);               % back to spatial domain
    xy_smooth = [real(z_s), imag(z_s)];

    % Package coeffs for reuse
    coeffs.M  = M;
    coeffs.K  = K;
    coeffs.Z  = Z;
    coeffs.Zf = Zf;
    coeffs.c  = c;                  % not strictly needed here
end
