function [mvcDictionary, flags, mvcFilesDict] = processMVC(settings)
%% processMVC - Extracts and processes MVC EMG data & exports to .sto file
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
%   settings.mvc_directory              | string                | Full path to a folder containing the mvc experiments (.c3d)
%   settings.mvc_results_dir            | string                | Path to save the resulting .sto files
%   settings.mvc_save_error             | boolean               | optional: save signals with possible error
%   settings.mvc_muscle_experiment      | dictionary            | optional: dictionary mapping the muscles to an MVC experiment
%   settings.emg_remove_flags           | struct                | optional: structure indicating bad EMG signals to remove for MVC processing
%   settings.emg_desired_channels       | Nx1 string array      | optional: list of EMG channels to extract
%   settings.emg_dictionary             | dictionary            | optional: rename emg channels inside dictionary
%   settings.emg_c3d_identifier         | string                | optional: identifier for EMG channels in C3D data        
%   settings.emg_bandpassFilterOrder    | integer               | optional: bandpass filter order
%   settings.emg_lowpassFilterOrder     | integer               | optional: lowpass filter order
%   settings.emg_bandpassFreqLow        | double                | optional: bandpass lower frequency limit               
%   settings.emg_bandpassFreqHigh       | double                | optional: bandpass higher frequency limit   
%   settings.emg_lowpassFreq            | double                | optional: lowpass frequency limit   
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% mvcDictionary                         | dictionary            | Dictionary of muscles & maximal values found across MVC trials
% flags                                 | struct                | Structure containing possible bad EMG signal flags
% mvcFiles                              | dictionary            | Dictionary of muscles & mvc files used
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% ezc3d toolbox                         | https://github.com/pyomeca/ezc3d
% OpenSim MATLAB API (osimC3D)          | https://github.com/opensim-org/opensim-core/blob/main/Bindings/Java/Matlab/Utilities/osimC3D.m
%
%------------------------------------------------------------- TO DO's ------------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Couëdel Romane, Menthy Denayer
% Date: 19/May/2025

% Last Update: Menthy Denayer
% Date: 13/Aug/2026 : added save for MVC files

%% Import OpenSim Java Libraries
import org.opensim.modeling.*

%% Read Settings
mvcDir = settings.mvc_directory;

%% Find MVC Files
dirInfo = struct2table(dir(mvcDir));
[~,~,fileExtensions] = fileparts(dirInfo.name);
mvcFiles = string(dirInfo.name(ismember(fileExtensions, ".c3d")));
Nfiles = length(mvcFiles); 

%% Default Settings
% results directory
if(~isfield(settings,"mvc_results_dir"))
    settings.mvc_results_dir = "";
end

% If you want to scale the muscles based on a specific MVC experiment 
% instead of the maximal value over all experiments.
if isfield(settings, "mvc_muscle_experiment")      
    muscleExpMap = settings.mvc_muscle_experiment;                          % map of muscles to experiments for use in MVC scaling
    muscleKeys = muscleExpMap.keys;                                         % muscle names
    muscleVals = muscleExpMap.values;                                       % files or keywords to use for MVC scaling
    Nkeys = length(muscleKeys);         
    useExp = zeros(Nfiles, Nkeys);                                          % max is taken only for specified experiments per muscle
    
    % loop over muscles & files to assign files to muscles
    for muscleIdx = 1:Nkeys
        for fileIdx = 1:Nfiles
            if(contains(mvcFiles(fileIdx),muscleVals(muscleIdx)))           % if the file contains the desired keyword, data is used to find the MVC value for this muscle
                useExp(fileIdx, muscleIdx) = 1;
            end
        end
    end
end

%% Process MVC Files
settings.emg_normalize = false;                                             % MVC signals don't need to be normalized
settings.save_sto = false;                                                  % don't save to .sto to prevent many files being created
settings = rmfield(settings, "mvc_directory");                              % remove mvc directory field otherwise we create an infinite loop

if(~isfield(settings,"mvc_save_error"))
    settings.mvc_save_error = false;
end

if(isfield(settings,"emg_remove_flags"))
    flags = settings.emg_remove_flags;
end

if(~isfield(settings,"mvc_error_threshold"))
    settings.mvc_error_threshold = Inf;
end

if(~isfield(settings,"mvc_rms_threshold"))
    settings.mvc_rms_threshold = 0;
end

if(settings.mvc_save_error)
    err_settings = settings; err_settings.save_sto = true;
    err_settings.export_original = true;
end

f = waitbar(0, 'Processing data...');
% Loop over MVC files
for fileIdx = 1:Nfiles
    settings.c3d_path_file = char(fullfile(mvcDir, mvcFiles(fileIdx)));     % MVC file location
    [~, emgTable] = EMGtoSTO(settings);                                     % OpenSim table with EMG data
    muscleStruct = osimTableToStruct(emgTable);
    muscleNames = fieldnames(muscleStruct);                                 % muscles in the table
    muscleNames = string(muscleNames(muscleNames~="time"));                 % time is not used for MVC scaling
    Nmuscles = length(muscleNames);
    maxActivations = zeros(Nmuscles, 1);                                    % max activations found for each muscle
    maxTests = strings(Nmuscles,1);                                         % tests where max activations occur
    
    waitbar(fileIdx/Nfiles, f, ['Processing file: ' char(replace(mvcFiles(fileIdx),"_"," ")) ' (' num2str(fileIdx) '/' num2str(Nfiles) ')'])
    % Loop over muscles & find maximal activations
    for muscleIdx = 1:Nmuscles
        currMax = max(muscleStruct.(muscleNames(muscleIdx)));
        currRMS = rms(muscleStruct.(muscleNames(muscleIdx)));
        currFile = mvcFiles(fileIdx);
        if(currMax > settings.mvc_error_threshold || currRMS < settings.mvc_rms_threshold) % threshold to tweak
            fprintf(['Possible bad signal for ' char(muscleNames(muscleIdx)) ', in file ' char(currFile) '\n'])
            if(settings.mvc_save_error)
                err_settings.c3d_path_file = char(fullfile(mvcDir, mvcFiles(fileIdx)));
                EMGtoSTO(err_settings);
            end
            [~,fileName,~] = fileparts(mvcFiles(fileIdx));
            flags.(fileName).(muscleNames(muscleIdx)) = 1;
        else
            if(isfield(settings,"emg_remove_flags"))
                [~,fileName,~] = fileparts(mvcFiles(fileIdx));
                if(isfield(settings.emg_remove_flags,fileName))
                    if(isfield(settings.emg_remove_flags.(fileName),muscleNames(muscleIdx)))
                        fprintf(['Flagged bad signal for ' char(muscleNames(muscleIdx)) ', in file ' char(currFile) '\n'])
                    else
                        maxActivations(muscleIdx) = currMax;
                        maxTests(muscleIdx) = currFile;
                    end
                else
                    maxActivations(muscleIdx) = currMax;
                    maxTests(muscleIdx) = currFile;
                end
            else
                maxActivations(muscleIdx) = currMax;
                maxTests(muscleIdx) = currFile;
            end
        end
    end

    % Compare found max to stored maximum & update when bigger
    if(fileIdx > 1)
        higherActivation = maxActivations > mvcActivations & useExp(fileIdx,:)';
        mvcActivations(higherActivation) = maxActivations(higherActivation);
        mvcTests(higherActivation) = mvcFiles(fileIdx);

        % disp(['MVC test: ', char(mvcFiles(fileIdx)'), ', higher activation found for: ', char(strjoin(muscleNames(higherActivation),", "))])
    else
        mvcActivations = maxActivations;                                    % first file is used to initialize the arrays
        mvcTests = maxTests;
        if(~exist("useExp","var"))
            useExp = ones(Nfiles, Nmuscles);                                % max is taken over all experiments per muscle
        end
    end

end
close(f)

%% Create Dictionary
mvcDictionary = dictionary(muscleNames, mvcActivations);
mvcFilesDict = dictionary(muscleNames, mvcTests);

%% Save Results
MVCfileName = fullfile(settings.mvc_results_dir, "MVCprocessed.mat");
MVCfileName2 = fullfile(settings.mvc_results_dir, "MVCfiles.mat");
save(MVCfileName, "mvcDictionary");
save(MVCfileName2, "mvcFilesDict");

%% Log Results
for muscleIdx = 1:Nmuscles
    disp(['Maximal value found for ', char(muscleNames(muscleIdx)), ' in experiment ', char(mvcTests(muscleIdx))])
end

%% Save Flags Structure
% if exist("flags", "var")
%     save(settings.mvc_results_dir + "/flags.mat", "flags")
% else
%     flags = 0;
% end

if ~exist("flags","var")
    flags = [];
end