function combinedVertices = getCombinedVertices(T)
    for rowIdx = 1:height(T)
        vertices = T.Mesh{rowIdx}.Vertices;
        if rowIdx == 1
            combinedVertices = vertices;
        else
            combinedVertices = [combinedVertices; vertices];
        end
    end
end