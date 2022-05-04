function [x, y, intensity] = calculate_PA_coordinates()
%dir_ = uigetdir('..\..\data');
%dir_ = path;
dir_ = 'G:\JHU\EN. 601.656 Computer Integrated Surgery 2\cis2_code\cis2\scan_-05deg'; % use full path of the folder storing .daq files
bFreqFilter_ = 1;
pub_image = ros.Publisher(ros_node, '/PA_image', 'sensor_msgs/Image','DataFormat','struct');

%% DAQ data acquisition setup
frameNum = 400;
numSample = 600;

%% read DAQ data
[mRcvData,vRcvData] = readDAQData(dir_, frameNum, numSample);

%% visualization
% figure(1);
% imagesc(db((mRcvData/max(mRcvData(:))))); title('Averaged');
% colormap gray
% 
% set(gcf,'Position',[230 80 553 899]);

%% filter
if(bFreqFilter_)
    idx = 96;
    freqBW = [0.05 0.2];
    [filteredmRcvData] = frequencyFiltering_(idx,freqBW,mRcvData);
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
bf_.dth = 30e-3;
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
%figure(1);
figure('visible','off')

img_orig = imagesc(axis_x*1e3, axis_z*1e3, env_data);%/max(env_data(:))));
orig = img_orig.CData;

%figure(2)
figure('visible','off')
img = imagesc(axis_x*1e3, axis_z*1e3, (env_data/max(env_data(:))));
x_coord = img.XData;
y_coord = img.YData;

% colormap default; colorbar;
% xlabel('lateral (mm'); ylabel('axial (mm');
% axis equal; axis tight;
% caxis([0 1]);
% set(gcf,'Position',[784 520 1079 421]);
% set(gca,'FontSize',14,'FontWeight','bold');

%% calculate the centroid coordinates and intensity of PA spot
img_gray = im2gray(img.CData);
BW = imbinarize(img_gray,0.8);
% figure(3)
% imshow(BW);
% hold on

BW = bwareaopen(BW, 5);
if (~any(BW))
    x = 0;
    y = 0;
    intensity = 0;
    disp('no spot found!')
    return
end

L = bwlabel(BW);
stats = regionprops(L);
area = cat(1, stats.Area);
centroids = cat(1, stats.Centroid);
idx = find(area == max(area));
center_pos = centroids(idx,:);
BW(find(L~=idx)) = 0;
img_after_mask = BW .*  orig;
%intensity = sum(img_after_mask, 'all');

center_mm(1) = interpn(1:numel(x_coord), x_coord, center_pos(1));
center_mm(2) = interpn(1:numel(y_coord), y_coord, center_pos(2));
%intensity = interpn(y_coord, x_coord, img_gray, center_mm(2), center_mm(1),'spline');
intensity = interpn(y_coord, x_coord, orig, center_mm(2), center_mm(1),'spline');

if intensity < 6 
    disp('don not find a PA spot!');
    x = 0;
    y = 0;
    intensity = 0;
    return;
end
x = center_pos(1);
y = center_pos(2);

% send image to the GUI
msg_image = rosmessage(pub_image); 
msg_image.Data = orig;
orig = orig.plot(x, y)
% ------------------------
rgb = cat(3,orig,orig,orig);
rgb = PointCircle(rgb, 5, x, y, [255, 0, 0]);
imshow(rgb)
%---------------------------
send(pub_image, msg_image);
clear('pub_image');
% disp(x)
% disp(y)
% disp(intensity)
% figure(4)
% imshow(img_gray);
% hold on
% plot(center_pos(1), center_pos(2), 'r*');
end