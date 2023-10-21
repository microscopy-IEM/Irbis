% IS created 230922

function single_zstack = IS_getSingleZstack_default();
    for i = 1:27;
        imtemp = im2double(imread('toolbox_fast_marching\data\smallDendrite_z_stack.tif'),i);
        im(:,:,1) 
    single_zstack = WF_zstack(:,:,:,1,1);
    imshow(single_zstack(:,:,15));
end