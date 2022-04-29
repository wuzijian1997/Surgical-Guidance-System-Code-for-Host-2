function [vRcvData, num_frame] = readData(dir_,file_name,headerSize,frame_size,num_frame,linesPerFrame, rx_offset_idx)
disp('>>> read data');
%Read RF-file
fid = fopen([dir_ file_name],'r');
[dataFromFile] = fread(fid,inf,'short');
fclose(fid);  

%Sort frames
num_frame = num_frame-1;           %drop first frame as invalid, as described in forum
frames = zeros(frame_size/2,num_frame);  %create empty matrix (speeds up copying)
for i = 1:num_frame                     %copy whole frames in matrix
    frames(:,i) = dataFromFile(i*frame_size/2+1:(i+1)*frame_size/2);
end

%Split up frames into scanlines
samplesPerLine = ((frame_size-headerSize)/2)/linesPerFrame;
vRcvData = zeros(int64(samplesPerLine),int64(linesPerFrame),int64(num_frame)); %empty 3d-matrix to hold lines
for i = 1:num_frame                             
    for j = 1:linesPerFrame
        vRcvData(:,j,i) = frames(((j-1)*int64(samplesPerLine)+1):j*int64(samplesPerLine),i);
    end
end

vRcvData = vRcvData(rx_offset_idx:end,:,:);
disp('    done');
end

