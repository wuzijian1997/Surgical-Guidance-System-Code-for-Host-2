clc; clear; close all;

rx_offset = 1e-6;
%% set beamforming parameter

% acoustic parameter
acoustic_.fc = 9e6;
acoustic_.c = 1540;
acoustic_.fs = 40e6;
acoustic_.unit_dis = acoustic_.c/acoustic_.fs;
acoustic_.lambda = acoustic_.c/acoustic_.fc;

% transducer parameter
trans_.pitch = 460e-6;
trans_.num_ele = 128;

% beamforming parameter
bf_.scline = 128;
bf_.dth = 40e-3;
bf_.dth_spl = ceil(bf_.dth/acoustic_.unit_dis*2);
bf_.f_num = 1; % receive f-number
bf_.ch = 128;

% mid-processing parameter
mid_.nTGC_Atten = 0.5;                                              % [dB]
mid_.nDCRType = 'high';
mid_.nDCRTap = 128;                                             % BPF tap #
mid_.nDCRFcut = 1e6;

%% get file
[file_name, dir_] = uigetfile('.rf');

disp(file_name);

headerSize = 4;         %Size of frame header in bytes (constant if not changed by a new version of Texo)
frame_size = 532480;      %Size of a single frame in bytes
num_frame = 251;     
linesPerFrame = 128;      %Number of scanlines per frame

[raw_data, num_frame] = readData(dir_,file_name,headerSize,frame_size,num_frame,linesPerFrame, round(rx_offset*acoustic_.fs));

%% filtering
Passband = 0.3e6;
PassbandW = Passband/acoustic_.fs*2;

Fil = fir1(127,PassbandW, 'high');

raw_data = convn(raw_data, Fil','same');
%% beamfomring
avg_first = 1;

disp('>>> beamforming');
if(avg_first)
    raw_data_mean = mean(raw_data,3);
    [bfed_data, axis_x, axis_z] = PABeamformer(raw_data_mean,acoustic_,trans_,bf_);
else
    v_bfed_data = [];
    for f_idx = 1:num_frame
        if(mod(f_idx,round(num_frame/4))==0), disp(['    ' num2str(round(100*f_idx/num_frame)) '%...']); end
        [bfed_data, axis_x, axis_z] = PABeamformer(raw_data(:,:,f_idx),acoustic_,trans_,bf_);
        v_bfed_data = cat(3, v_bfed_data, bfed_data);
    end
    % average after
    num_avg = num_frame;
    bfed_data = mean(v_bfed_data(:,:,1:num_avg),3);
end

%% mid processing
disp('>>> mid processing');
env_data = mid_proc(bfed_data, mid_, acoustic_, bf_);

%% DSC
disp('>>> dsc');
height_img = 35e-3;
width_img = 60e-3;
dx = 0.5e-4;
dz = 0.5e-4;
nHeight = round(height_img / dz);
nWidth = round(width_img / dx);

[aXAxis, aZAxis, mOutput] = ScanConverter_linear(env_data, trans_.pitch, acoustic_.unit_dis, nHeight, nWidth, dz, dx);
%% plot image
figure;
imagesc(aXAxis*1e3, aZAxis*1e3, db(mOutput/max(mOutput(:))));
colormap gray; caxis([-40 0]); colorbar;
xlabel('lateral (mm'); ylabel('axial (mm');
axis equal; axis tight;
set(gcf,'Position',[1441 910 890 427]);
set(gca,'FontSize',14,'FontWeight','bold');





