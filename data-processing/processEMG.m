function emgDataNorm = processEMG(emgDataRaw, emgLabels, FS, settings)
%% processEMG - performs bandpass filtering, rectification & low pass filtering
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% emgDataRaw                            | NxM double array      | Raw EMG data to process
% emgLabels                             | 1xM string array      | List of muscle labels
% FS                                    | double                | Sampling frequency
% settings                              | struct                | Configuration structure with fields:
%   settings.emg_bandpassFilterOrder    | integer               | optional: bandpass filter order
%   settings.emg_lowpassFilterOrder     | integer               | optional: lowpass filter order
%   settings.emg_bandpassFreqLow        | double                | optional: bandpass lower frequency limit               
%   settings.emg_bandpassFreqHigh       | double                | optional: bandpass higher frequency limit   
%   settings.emg_lowpassFreq            | double                | optional: lowpass frequency limit   
%   settings.emg_normalize_emg          | boolean               | optional: normalize EMG signal to max value
%   settings.emg_mvc_dictionary         | dictionary            | optional: match muscle names & max. contraction value
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% emgDataNorm                           | NxM double array      | Processed EMG data
%
%------------------------------------------------------------- TO DO's ------------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

%% Add Utilities
[pathHere,~,~] = fileparts(mfilename('fullpath'));
addpath(fullfile(pathHere,"utilities"));

%% Default Settings
if ~isfield(settings,"emg_bandpassFilterOrder")
    settings.emg_bandpassFilterOrder = 4;
end

if ~isfield(settings,"emg_lowpassFilterOrder")
    settings.emg_lowpassFilterOrder = 4;
end

if ~isfield(settings,"emg_bandpassFreqLow")
    settings.emg_bandpassFreqLow = 10;
end

if ~isfield(settings,"emg_bandpassFreqHigh")
    settings.emg_bandpassFreqHigh = 300;
end

if ~isfield(settings,"emg_lowpassFreq")
    settings.emg_lowpassFreq = 4;
end

if ~isfield(settings,"emg_normalize")
    settings.emg_normalize = true;
end

%% Initialize Settings
bandpassFilterOrder = settings.emg_bandpassFilterOrder;
lowpassFilterOrder = settings.emg_lowpassFilterOrder;
bandpassFreqLow = settings.emg_bandpassFreqLow;                                 % Hz
bandpassFreqHigh = settings.emg_bandpassFreqHigh;                               % Hz
lowpassFreq = settings.emg_lowpassFreq;                                         % Hz
normalize = settings.emg_normalize;

%% Bandpass Filter Using Nth-order Reversed Butterworth Filter 
% default: 4th order, [10 - 300 Hz]
[b, a] = butter(bandpassFilterOrder, [bandpassFreqLow bandpassFreqHigh] / (FS / 2), 'bandpass');
emgDataButter = filtfilt(b, a, emgDataRaw);

%% Full Wave Rectification 
% take absolute value of signal
emgDataRectified = abs(emgDataButter);

%% Lowpass Filter Using Mth-order Butterworth Filter, Linear Envelope 
% default: 4th order, [2 Hz]
[d, c] = butter(lowpassFilterOrder, lowpassFreq / (FS / 2), 'low');
emgDataLinear = filtfilt(d, c, emgDataRectified);

%% Normalize Amplitude to Max Value
if normalize
    if ~isfield(settings, "emg_mvc_dictionary")
        disp('Did not find MVC data to scale EMG signals. Using maximal over time instead...')
        emgDataMax = max(emgDataLinear, [], 1);
    else
        disp('Found MVC data to scale EMG signals!')
        emgLabels = strrep(strrep(emgLabels," ","_"),".","_");
        Nemg = length(emgLabels);
        emgDataMax = zeros(1,Nemg);
        for muscleIdx = 1:Nemg
            emgDataMax(muscleIdx) = settings.emg_mvc_dictionary(emgLabels(muscleIdx));
        end
    end
    emgDataNorm = emgDataLinear ./ emgDataMax;
else
    emgDataNorm = emgDataLinear;
end

%% Plot Processed Data
% Nemg = length(emgLabels);
% for muscleIdx = 1:Nemg
%     figure
%     hold on
%     plot(emgDataRaw(:,muscleIdx),"LineWidth",1,"Color","black")
%     plot(emgDataNorm(:,muscleIdx),"LineWidth",1,"Color","blue")
%     hold off
% end

end