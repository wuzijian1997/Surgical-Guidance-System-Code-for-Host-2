function [mDCROut, Fil] = DCR( mBFedData , stMID, stRFInfo)
switch stMID.nDCRType
    case 'bandpass'
        Passband = [stMID.nDCRF1 stMID.nDCRF2];
        PassbandW = Passband/stRFInfo.fs*2;
    case 'high'
        Passband = stMID.nDCRFcut;
        PassbandW = Passband/stRFInfo.fs*2;
end

%     Fil = fir1(stMID.nDCRTap,[0.234 0.6],'bandpass');
Fil = fir1(stMID.nDCRTap,PassbandW, stMID.nDCRType);

mDCROut = convn(mBFedData, Fil','same');

% disp(['>>> DCR <<< filter type: ' stMID.nDCRType '>>>']);
end
