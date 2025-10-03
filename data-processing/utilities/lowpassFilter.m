function processedData = lowpassFilter(rawData, FS, settings)
%% lowpassFilter - Lowpass filter using Nth-order Butterworth filter
% - If NaN data is present, it is removed from the rawData
% - NaN data is reset at the end, only non-NaN data is filtered
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% rawData                               | NxM double array      | data to filter
% FS                                    | double                | data sampling frequency
% settings                              | struct                | Configuration structure with fields:
%   settings.lowpassFreq                | double                | optional: lowpass frequency limit 
%   settings.lowpassFilterOrder         | integer               | optional: lowpass filter order
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% processedData                         | NxM double array      | filtered data containing original NaNs
%
%------------------------------------------------------------- CREDITS -----------------------------------------------------------
% Add flipped signal to beginning & end to prevent edge effects
% Based on: https://nl.mathworks.com/matlabcentral/answers/161223-how-to-remove-transient-effect-in-the-beginning-of-the-filtered-signal#answer_328445
%
%----------------------------------------------------------------------------------------------------------------------------------

%% Default Settings
if ~isfield(settings, "lowpassFreq")
    settings(1).lowpassFreq = 20;
end

if ~isfield(settings, "lowpassFilterOrder")
    settings(1).lowpassFilterOrder = 2;
end

%% Initialize Settings
filterOrder = settings.lowpassFilterOrder;
filterFreq = settings.lowpassFreq;
percentEdgePoints = 0.1;                                                    % 10% of signal
maxEdgePoints = 50;
[Nrow, Ncol] = size(rawData);

%% Apply Lowpass Filter
processedData = zeros(Nrow, Ncol);
for colIdx = 1:Ncol
    processedData(:,colIdx) = runLowpassFilter(rawData(:,colIdx), percentEdgePoints, maxEdgePoints, filterOrder, filterFreq, FS);             
end

end

%% Lowpass Filter Function
function processedData = runLowpassFilter(rawData, percentEdgePoints, maxEdgePoints, filterOrder, filterFreq, FS)
    % Extract non-NaN Data
    isNaN = isnan(rawData);
    noNanData = rawData(~isNaN);

    if(~isempty(noNanData))
        % Initialize Settings
        [Ndata, ~] = size(noNanData);
        NedgePoints = min(round(Ndata*percentEdgePoints), maxEdgePoints);       % At most N points
        
        % Extend Data
        preData = 2*noNanData(1)-flipud(noNanData(2:NedgePoints+1));            % maintain continuity in level and slope
        postData = 2*noNanData(end)-flipud(noNanData(end-NedgePoints:end-1));
        
        extData = [preData; noNanData; postData];
        
        % Create a Lowpass Filter with Desired Properties
        [d,c] = butter(filterOrder, filterFreq/(FS/2), 'low');
        
        % Apply Filter to EMG Signal
        filteredData = filtfilt(d, c, extData);
        
        % Remove additional data
        filteredData = filteredData(NedgePoints+1:end-NedgePoints); 
        
        % Restore NaN values
        processedData = rawData;
        processedData(~isNaN) = filteredData;
    else
        processedData = rawData;
    end

    % figure
    % hold on
    % plot(rawData,'Color','blue')
    % plot(extData,'k--')
    % plot(processedData,'LineStyle','--','Color','red')
    % hold off

end