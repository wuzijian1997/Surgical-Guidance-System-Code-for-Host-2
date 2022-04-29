function [mTGCOut, aTGCCurve] = fDTGC(mImgData, stMID, stRFInfo, stBFInfo, nXMax, unit_dis)
% disp('>>> DTGC <<<Attenuation coef: 0.5 dB/cm*MHz >>>');
aX_tmp = 1:nXMax;
% aX = 100*aX_tmp*stRFInfo.nUnitDis/2;                                         % depth [cm]
% nUnitDis = mImgData(2,1) - mImgData(1,1);
aX = 100*aX_tmp*unit_dis/2;                                         % depth [cm]

nBeta = stMID.nTGC_Atten;                                                     % [dB]                    
nFreq = stRFInfo.fc/1e6;                                                      % [MHz]
aZ = aX;                                                                      % [cm]

aTGCCurve = 10.^(nBeta*nFreq*aZ/20);
mTGCCurve = repmat(aTGCCurve.', 1, stBFInfo.scline);

mTGCOut = mImgData.*mTGCCurve;
end