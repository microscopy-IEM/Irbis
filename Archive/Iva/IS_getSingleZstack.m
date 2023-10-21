% IS created 230922

function single_zstack = IS_getSingleZstack(WF_zstack);
    single_zstack = WF_zstack(:,:,:,1,1);
    imshow(single_zstack(:,:,15));
end