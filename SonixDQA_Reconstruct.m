%clear, clc, close all;

% dir_ = uigetdir('..\..\data');
%dir_ = 'G:\JHU\EN. 601.656 Computer Integrated Surgery 2\paTest'; 
% use full path
dir_ = 'G:\JHU\EN. 601.656 Computer Integrated Surgery 2\PA_buf2000';
%dir_ = 'G:\offline_data_phantom\5\degree0';
bFreqFilter_ = 1;   

%% DAQ data acquisition setup
frameNum = 145;
numSample = 1800;

%% read DAQ data
[mRcvData,vRcvData] = readDAQData(dir_, frameNum, numSample);

%% visualization
trim_ = 25;
mRcvDataTrim = mRcvData(trim_:end,:);
figure(1);
imagesc(((mRcvDataTrim/max(mRcvDataTrim(:))))); title('Averaged');
colormap gray

set(gcf,'Position',[81 81 400 670]);

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
acoustic_.c = 1540;
acoustic_.fs = 40e6;
acoustic_.unit_dis = acoustic_.c/acoustic_.fs;
acoustic_.lambda = acoustic_.c/acoustic_.fc;

% transducer parameter
trans_.pitch = 420e-6;
trans_.num_ele = 128;

% beamforming parameter
bf_.scline = trans_.num_ele;
bf_.dth = 60e-3;
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
%imagesc(axis_x*1e3, axis_z*1e3, (env_data/max(env_data(:))));
max(env_data(:))
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
max_intensity = max(intensity,[],'all');

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

figure(27)
imagesc(axis_x*1e3, axis_z*1e3,img_gray);
hold on
plot(center_pos_mm(:,1)*1e3, center_pos_mm(:,2)*1e3, 'r*');
axis tight; axis equal;
