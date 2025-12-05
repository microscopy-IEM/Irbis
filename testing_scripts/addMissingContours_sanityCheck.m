function output = addMissingContours_sanityCheck(checked, BEmpty, BClosest, version)
    
    AEmpty = [0,0,0];
    AClosest = [0,0,0];
    NormalVectorEmpty = (BEmpty - AEmpty)/norm(BEmpty - AEmpty);
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

    if isequal(version, 'original')
        output = checked * R;
    elseif isequal(version, 'inverse')
        output = checked * R';
    end
end