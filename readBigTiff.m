function img_matrix = readBigTiff(full_fn, frame_range)
% author: Isaac Li
% version: 20230923 this function reads tiff of any size by indexing directly into file position.
% input:	full_fn: full file path with file name
%			frame_range: [f1 f2] - inclusive start and end frame. auto
%						 error handling to make sure f1 f2 fall into range.
%						 [f1] - specifying a single value meaning reading
%						 the only frame
% output:	img_matrix: [W H num_frame]
	iminfo	= imfinfo(full_fn);
	% get file parameters
	num_frame	= round((iminfo(1).FileSize-iminfo(1).StripOffsets)/iminfo(1).StripByteCounts);
	bit_depth	= iminfo(1).BitsPerSample;
	byte_order	= iminfo(1).ByteOrder;
    w			= iminfo(1).Width;
    h			= iminfo(1).Height;	
	switch byte_order
		case 'big-endian'; 		fread_bo = 'b';
		case 'little-endian';	fread_bo = 'l';
	end
	% error and input handling
	if nargin<3;					frame_range = [1 num_frame];				end
	if length(frame_range)==1;		frame_range = [frame_range frame_range];	end		% taking care of case when there's a single input for a single frame
	if frame_range(1)<1;			frame_range(1)=1;							end
	if frame_range(2)>num_frame;	frame_range(2)=num_frame;					end
	frame_range = frame_range-1;
    
    % Initialize image data array
	if		bit_depth == 8;		img_matrix = zeros(h, w, diff(frame_range)+1, 'uint8');
	elseif	bit_depth == 16;	img_matrix = zeros(h, w, diff(frame_range)+1, 'uint16');
	elseif	bit_depth == 32;	img_matrix = zeros(h, w, diff(frame_range)+1, 'uint32');
	end
	fID = fopen (full_fn, 'r');
	startPoint = iminfo(1).StripOffsets + (frame_range(1):frame_range(2))*iminfo(1).StripByteCounts;	% must not +1 here!
	for i = 1:diff(frame_range)+1
    	fseek (fID, startPoint(i), 'bof'); 
		if		bit_depth == 8;		img = fread (fID, [w h], 'uint8=>uint8' , fread_bo);
		elseif	bit_depth == 16;	img = fread (fID, [w h], 'uint16=>uint16' , fread_bo);
		elseif	bit_depth == 32;	img = fread (fID, [w h], 'uint32=>uint32' , fread_bo);
		end
    	img_matrix(:,:,i) = img';
	end
	fclose(fID);
end
