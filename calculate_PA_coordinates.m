function [x, y, max_intensity] = calculate_PA_coordinates(ros_node, degree)
dir_ = 'G:\JHU\EN. 601.656 Computer Integrated Surgery 2\PA_buf2000'; % use full path of the folder storing .daq files
bFreqFilter_ = 1;
pub_image = ros.Publisher(ros_node, '/naive_registration/Display/PA_Image', 'sensor_msgs/Image','DataFormat','struct');

%% DAQ data acquisition setup
frameNum = 145;
numSample = 1800;
%% read DAQ data
[mRcvData,vRcvData] = readDAQData(dir_, frameNum, numSample);

%% visualization
trim_ = 25;
mRcvDataTrim = mRcvData(trim_:end,:);
% figure(1);
% imagesc(db((mRcvData/max(mRcvData(:))))); title('Averaged');
% colormap gray
% 
% set(gcf,'Position',[230 80 553 899]);

%% filter
if(bFreqFilter_)
    idx = 65;
    freqBW = [0.05 0.2];
    [filteredmRcvData] = frequencyFiltering_(idx,freqBW,mRcvDataTrim);
else
    filteredmRcvData = mRcvDataTrim;
end

%% parameter setup
% acoustic parameter
acoustic_.fc = 6.5e6;
acoustic_.c = 1590;
acoustic_.fs = 40e6;
acoustic_.unit_dis = acoustic_.c/acoustic_.fs;
acoustic_.lambda = acoustic_.c/acoustic_.fc;

% transducer parameter
trans_.pitch = 420e-6;
trans_.num_ele = 128;

% beamforming parameter
bf_.scline = trans_.num_ele;
bf_.dth = 60e-3;%30e-3;
bf_.dth_spl = ceil(bf_.dth/acoustic_.unit_dis);
bf_.f_num = 1; % receive f-number
bf_.ch = 128;

% mid-processing parameter
mid_.nTGC_Atten = 0.5;                                              % [dB]
mid_.nDCRType = 'high';
mid_.nDCRTap = 128;                                             % BPF tap #
mid_.nDCRFcut = 1e6;

%% beamforming
[bfed_data, axis_x, axis_z] = PABeamformer(filteredmRcvData,acoustic_,trans_,bf_);

env_data = mid_proc(bfed_data, mid_, acoustic_, bf_);

%% plot image
figure(25);
% figure('visible','off')
max_intensity = max(env_data(:));
img = imagesc(axis_x*1e3, axis_z*1e3, (env_data/max(env_data(:))));
colormap default; colorbar;
xlabel('lateral (mm'); ylabel('axial (mm');
axis equal; axis tight;
caxis([0 1]);
set(gcf,'Position',[99.4000 162.6000 512 420.8000]);
set(gca,'FontSize',14,'FontWeight','bold');
x_coordinates = img.XData;
y_coordinates = img.YData;
intensity = img.CData;

%% calculate the centroid coordinates and intensity of PA spot

img_gray = im2gray(img.CData);
BW = imbinarize(img_gray,0.8);
[L, num] = bwlabel(BW);
stats = regionprops(L);
area = cat(1, stats.Area);
centroids = cat(1, stats.Centroid);
idx = find(area == max(area));
center_pos = centroids(idx,:);
center_pos_mm = zeros(1,2);
center_pos_mm(1) = interpn(1:128,axis_x,center_pos(1));
center_pos_mm(2) = interpn(1:bf_.dth_spl,axis_z,center_pos(2));
disp(strcat('x_coordinate:, ',string(center_pos_mm(1))));
disp(strcat('y_coordinate:, ',string(center_pos_mm(2))));
disp(strcat('intensity:, ',string(max_intensity)));

figure(27)
I = imagesc(axis_x*1e3, axis_z*1e3,img_gray);
hold on
plot(center_pos_mm(:,1)*1e3, center_pos_mm(:,2)*1e3, 'r*');
axis tight; axis equal;

x = center_pos(1);
y = center_pos(2);
center_list = [];

% send image to the GUI
img_gray = im2gray(I.CData);
msg_image = rosmessage(pub_image); 
img_gray = transpose(img_gray);
rgb = cat(3,img_gray * 255,img_gray * 255,img_gray * 255);
rgb = PointCircle(rgb, 2, x, y, [0, 0, 255]);
rgb = uint8(rgb);
%imwrite(rgb, strcat('G:\JHU\EN. 601.656 Computer Integrated Surgery 2\ground_truth_images\', 'proc_img', num2str(degree), '.jpg'));
msg_image.encoding = 'bgr8';
msg_image.height = uint32(size(rgb,1));
msg_image.width = uint32(size(rgb,2));
msg_image.step = uint32(size(rgb,2) * size(rgb,3));
reshape_image = [];
for row_id = 1:size(rgb,1)
    row = squeeze(rgb(row_id,:,:));
    reshape_row = [];
    for col_id = 1:size(rgb,2)
        reshape_row = [reshape_row,row(col_id,:)];
    end
    reshape_image = [reshape_image, reshape_row];
end
msg_image.data = reshape_image;
send(pub_image, msg_image);
clear('pub_image');

end