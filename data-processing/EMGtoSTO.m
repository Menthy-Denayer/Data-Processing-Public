function [sto_file, emgTable] = EMGtoSTO(settings)
%% EMGtoSTO - Extracts and processes EMG data from a C3D file and exports it to .sto format
% - Only channels with 'Electric' in their name are considered EMG by default.
% - Channels with 'button', 'load', or 'sync' are excluded (to avoid non-muscular data).
% - The EMG is processed using:
%       * Band-pass filter (10–300 Hz)
%       * Full-wave rectification
%       * Low-pass filter (2 Hz) to get the linear envelope
%       * Optional normalization to maximum amplitude
% - Output format (.sto) is compatible with OpenSim's EMG-driven analyses.
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% settings                              | struct                | Configuration structure with fields:
%   settings.c3d_path_file              | string                | Full path to the .c3d input file
%   settings.sto_results_dir            | string                | Path to save the resulting .sto files
%   settings.save_sto                   | boolean               | optional: save emg results to .sto file (default: true)
%   settings.mocap_system               | string                | optional: Xsens if IMUs used
%   settings.mvc_directory              | string                | optional: full path to a folder or file containing the mvc experiments (.c3d/.mat)
%   settings.mvc_muscle_experiment      | dictionary            | optional: dictionary mapping the muscles to an MVC experiment
%   settings.emg_desired_channels       | Nx1 string array      | optional: list of EMG channels to extract
%   settings.emg_dictionary             | dictionary            | optional: rename emg channels inside dictionary
%   settings.emg_c3d_identifier         | string                | optional: identifier for EMG channels in C3D data        
%   settings.emg_bandpassFilterOrder    | integer               | optional: bandpass filter order
%   settings.emg_lowpassFilterOrder     | integer               | optional: lowpass filter order
%   settings.emg_bandpassFreqLow        | double                | optional: bandpass lower frequency limit               
%   settings.emg_bandpassFreqHigh       | double                | optional: bandpass higher frequency limit   
%   settings.emg_lowpassFreq            | double                | optional: lowpass frequency limit   
%   settings.emg_normalize              | boolean               | optional: normalize EMG signal to max value
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% sto_file                              | string                | Full path to the generated .sto file
% emgTable                              | Osim TimeSeries Table | Table containing the processed emg data
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% ezc3d toolbox                         | https://github.com/pyomeca/ezc3d
% OpenSim MATLAB API (osimC3D)          | https://github.com/opensim-org/opensim-core/blob/main/Bindings/Java/Matlab/Utilities/osimC3D.m
%
%------------------------------------------------------------- TO DO's ------------------------------------------------------------
% 
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Couëdel Romane, Menthy Denayer
% Date: 19/May/2025

% Last Update: Menthy Denayer
% Date: 30/May/2025 : added MVC processing

%% Import OpenSim Java Libraries
import org.opensim.modeling.*

%% Add Utilities
[pathHere,~,~] = fileparts(mfilename('fullpath'));
addpath(fullfile(pathHere,"utilities"));

%% Default Settings
% Output directory
if(~isfield(settings,"sto_results_dir"))
    settings.sto_results_dir = "";
    fprintf("No results directory selected for saving the sto files. Using the current one instead!")
end

% EMG normalization
if ~isfield(settings, 'emg_normalize')
    settings.emg_normalize = true;
end

% C3D EMG label identifier
if(~isfield(settings,'emg_c3d_identifier'))
    settings.emg_c3d_identifier = 'Electric';
    if(isfield(settings,'mocap_system'))
        if(string(settings.mocap_system) == "Xsens")
            settings.emg_c3d_identifier = 'Cometa';
        end
    end
end

% Save EMG to .sto file
if ~isfield(settings,"save_sto")
    settings.save_sto = true;
end

%% Initialize Settings
c3d_path_file = settings.c3d_path_file;
c3dIdentifier = settings.emg_c3d_identifier;

%% Define Output File Name
[~, filename, ~] = fileparts(c3d_path_file);
emgFilename = strcat(filename, '_emg_data.sto');
sto_file = fullfile(settings.sto_results_dir, emgFilename);

%% Load C3D File
c3d = ezc3dRead(c3d_path_file);
analog_labels = c3d.parameters.ANALOG.LABELS.DATA;                          % data labels
analog_data = c3d.data.analogs;                                             % data values
FS = c3d.parameters.ANALOG.RATE.DATA;                                       % sampling frequency
Nsamples = c3d.header.analogs.lastFrame-c3d.header.analogs.firstFrame+1;    % number of samples

%% Extract Valid EMG Channels
if isfield(settings, "desired_emg_channels")
    isExcluded = ~ismember(string(analog_labels), settings.emg_desired_channels);
    isEMG = ones(length(analog_labels),1);
else
    isEMG = contains(string(analog_labels), c3dIdentifier, "IgnoreCase", true);
    isExcluded = contains(string(analog_labels), ["button", "load", "sync"], "IgnoreCase", true);
end

emgLabels = string(analog_labels(isEMG & ~isExcluded));
emgDataRaw = analog_data(:,isEMG & ~isExcluded);

Nmuscles = length(emgLabels);
if Nmuscles == 0
    warning('No valid EMG channels found in the C3D file. No EMG file will be generated.');
    sto_file = ''; 
    return;
end

%% Rename EMG Channels
if isfield(settings, "emg_dictionary")                                      
    dicKeys = settings.emg_dictionary.keys;
    dicVals = settings.emg_dictionary.values;
    [locLabels, locDict] = ismember(emgLabels, dicKeys);                    % location of labels in column labels & dictionary
    emgLabels(locLabels) = dicVals(locDict(locDict>0));                     % new labels from dictionary
end

%% Process MVC Tests
if isfield(settings, "mvc_directory")
    if(~isfile(settings.mvc_directory))
        MVCsettings = settings;
        MVCsettings.emg_normalize = false;
        disp(['Processing MVC files inside of: ' char(settings.mvc_directory)])
        [settings.emg_mvc_dictionary,~,~] = processMVC(MVCsettings);
    else
        disp(['Using MVC results of: ' char(settings.mvc_directory)])
        MVCresultsStruct = load(settings.mvc_directory);
        settings.emg_mvc_dictionary = MVCresultsStruct.mvcDictionary;
    end
end

%% Filter & Process EMG
emgDataProcessed = processEMG(emgDataRaw, emgLabels, FS, settings);

%% Remove Failed EMG Signals
if isfield(settings,"emg_remove_flags")
    failedFiles = string(fieldnames(settings.emg_remove_flags));
    if any(contains(failedFiles,string(filename)))
        failedMuscles = string(fieldnames(settings.emg_remove_flags.(filename)));
        failedIdxs = contains(emgLabels, failedMuscles);
        emgDataProcessed(:,failedIdxs) = 0;
    end
end

%% Time Vector
duration = (Nsamples - 1) / FS;
timeVector = linspace(0, duration, Nsamples)';

%% Write original to .sto File
if ~isfield(settings,"export_original")
    settings.export_original = false;
end

if(settings.export_original)
    emgTableOrg = createTimeSeriesTable(emgLabels, timeVector, emgDataRaw);
    sto_file_org = strrep(sto_file,".sto","_original.sto");
    STOFileAdapter().write(emgTableOrg, sto_file_org);
    disp(['Original EMG data written to: ' char(sto_file_org)]);
end

%% Create EMG Data Table
emgTable = createTimeSeriesTable(emgLabels, timeVector, emgDataProcessed);

%% Write to .sto File
if(settings.save_sto)
    STOFileAdapter().write(emgTable, sto_file);
    disp(['Processed EMG data written to: ' char(sto_file)]);
end

end
