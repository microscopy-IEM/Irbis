imInv = imcomplement(binaryImage_high);

imshow(imInv)

r = drawfreehand;
mask = createMask(r);
maskInv = imcomplement(mask);

% figure
% imshow(maskInv)
%bw = activecontour(imcomplement(binaryImage),mask,200,'edge');
bw = activecontour(binaryImage_high,mask,400,'edge','ContractionBias',-0.3);

hold on
visboundaries(bw,'Color','r')

% figure
% imshow(labeloverlay(binaryImage,bw))

disp(size(bw))

% figure
% imshow(imcomplement(bw))

cont = contour(bw).';
ending = cont(1,2);
cont(1,:) = [];
cont(end)
disp(size(cont))
zc = zeros(size(cont,1),1);
cont3d = [cont,zc];
disp(size(cont3d))
cont3dS = simplify(polyshape(cont));
disp(size(cont3dS.Vertices))

simpCont = cont(1:ending,:);

