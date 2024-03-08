function Zprojection = getZProjection(zstack,refCh,Z_Range,timePoint,mode)
    Zprojection = [];
    
    switch mode
        case 'max'
            Zprojection = max(zstack(:,:,Z_Range,timePoint,refCh),[],3,"omitmissing");
        case 'mean'                   
            Zprojection = round(mean(zstack(:,:,Z_Range,timePoint,refCh),3,"omitmissing"));
        case 'median'
            Zprojection = median(zstack(:,:,Z_Range,timePoint,refCh),3,"omitmissing");
        case 'zstack'
            Zprojection = zstack(:,:,Z_Range,timePoint,refCh);
    end
end