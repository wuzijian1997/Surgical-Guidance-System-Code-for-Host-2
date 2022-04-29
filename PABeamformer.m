function [bfed_data, axis_x, axis_z] = PABeamformer(mRcvData,acoustic_,trans_,bf_)
%% grid setting
aEleIdx = linspace(-0.5*(trans_.num_ele-1), 0.5*(trans_.num_ele-1), trans_.num_ele);
aElePosX = aEleIdx * trans_.pitch;
aElePosZ = zeros(1, trans_.num_ele);

axis_x = linspace(aElePosX(1), aElePosX(end), bf_.scline);
axis_z = linspace(0, bf_.dth_spl * acoustic_.unit_dis, bf_.dth_spl);
[mPosZ, mPosX] = ndgrid(axis_z, axis_x);

%% beamforming
bfed_data = zeros(size(mPosX));

% receive aperture size
aper_size = mPosZ(:)/bf_.f_num + trans_.pitch;
for c_idx = 1:bf_.ch
    % receive distance
    aRD = sqrt((mPosX(:)-aElePosX(c_idx)).^2 + (mPosZ(:)-aElePosZ(c_idx)).^2);
    
    aDelay = aRD;
    
    aDistX = abs((mPosX(:) - aElePosX(c_idx)));
    %%%%    Aperture growth
    aApod = (aDistX <= 0.5 * aper_size); % boxcar
    
    aAddr = aDelay / acoustic_.unit_dis;
    aAddr = max(min(aAddr,size(mRcvData,1)-1),1);
    aLogic = (aAddr>0).*(aAddr<size(mRcvData,1)-1);
    
    aInterpData = interpn(0:1:size(mRcvData,1)-1,mRcvData(:,c_idx), aAddr, 'spline');
    bfed_data(:) = bfed_data(:) + aInterpData .* aLogic .* aApod;
end

end

