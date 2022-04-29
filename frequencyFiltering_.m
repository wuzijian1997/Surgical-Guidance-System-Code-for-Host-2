function [filteredmRcvData] = frequencyFiltering_(idx,freqBW_,mRcvData)
    %figure(2);
    %plot(mRcvData(:,idx));
    %figure(3);
    %freqz(mRcvData(:,idx));
    
    filter_ = fir1(65,[freqBW_(1), freqBW_(2)],'bandpass');
    filteredSignal_ = conv(mRcvData(:,idx),filter_,'same');
    
    %figure(4); plot(filteredSignal_);
    %figure(5); 
    %freqz(filteredSignal_);
    
    filteredmRcvData = zeros(size(mRcvData));
    for k = 1:128
        filteredmRcvData(:,k) = conv(mRcvData(:,k),filter_,'same');
    end
    
    %figure(6); imagesc((filteredmRcvData(1:end,:)/max(filteredmRcvData(1:end,:),[],'all'))); colormap gray;
    %set(gcf,'Position',[681 80 553 899]);    
end

