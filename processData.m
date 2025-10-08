clear all
clc
close all

%% ----------------------------- Description ------------------------------
% This code reads the raw C3D files, and extracts and processes the marker,
% ground reaction forces, and EMG data. It also performs MVC scaling,
% scaling of the last force plate to correct for the experimental offset,
% and extracts gait events.

% The user needs to select the following data directories and files:
%   o directory of the "ezc3d" library
%   o directory containing the C3D files (.c3d)
%   o EMG flags structure, containing files with bad EMG signals (.mat)

%% ------------------------------------------------------------------------

%% Find EZC3D Directory
ezc3dDIR = uigetdir("","Choose ezc3d directory");

%% Add Path to Repository
addpath("data-processing");
addpath("data-processing\utilities");
addpath(ezc3dDIR)

%% Choose C3D Directory
c3dDir = uigetdir("","Choose directory with .c3d files to process");
dirInfo = struct2table(dir(c3dDir));
[~,~,fileExtensions] = fileparts(dirInfo.name);
c3dFiles = string(dirInfo.name(ismember(fileExtensions, ".c3d")));
Nfiles = length(c3dFiles);  

%% Choose EMG Flags
emgFlagsPath = uigetfile(".mat", "Choose EMG flags file");

%% Define General Settings
results_directory = "SUBJ1";      
settings.mot_results_dir = results_directory;
settings.trc_results_dir = results_directory;
settings.sto_results_dir = results_directory;
settings.use_COP_as_moments_point = 1;
settings.export_original = false;

%% Marker Settings
% switching markers during processing if switched up during auto-labelling
% settings.marker_dictionary = dictionary(["RWRA", "RWRB"],["RWRB", "RWRA"]);

%% EMG Settings
emgNames = ["Electric Potential.Biceps Femoris", "Electric Potential.Semitendinosus", "Electric Potential.Rectus Femoris", "Electric Potential.Vastus Medialis", "Electric Potential.Vastus Lateralis", "Electric Potential.Gastrocnemius Medialis", "Electric Potential.Gastrocnemius Lateralis", "Electric Potential.Soleus"];
emgNames = [emgNames, emgNames + " Left"];
muscleNames = ["Biceps Femoris", "Semitendinosus", "Rectus Femoris", "Vastus Medialis", "Vastus Lateralis", "Gastrocnemius Medialis", "Gastrocnemius Lateralis", "Soleus"];
muscleNames = [muscleNames + " Right", muscleNames + " Left"];
muscleNames = replace(muscleNames," ","_");

settings.emg_normalize = true;
settings.emg_dictionary = dictionary(emgNames, muscleNames);

settings.emg_bandpassFilterOrder = 4;
settings.emg_lowpassFreq = 4;
settings.emg_bandpassFreqLow = 20;

%% Force Settings
settings.forces_lowpassFreq = 20;                              
settings.forces_threshold = 20;
settings.desired_forces = [4,2,3];

%% Process MVC Data
settings.emg_normalize = true;

% Use MVC experiments for scaling specific muscles
% MVCexpNames = ["KneeFlexion", "KneeFlexion", "KneeExtension", "KneeExtension", "KneeExtension", "AnklePlantarFlexion", "AnklePlantarFlexion", "AnklePlantarFlexion"];
% MVCexpNames = [MVCexpNames+"Right", MVCexpNames+"Left"];
% settings.mvc_muscle_experiment = dictionary(muscleNames, MVCexpNames);

settings.mvc_save_error = false;
settings.mvc_directory = c3dDir;
settings.mvc_results_dir = results_directory;

% remove EMG data based on max/min threshold
% settings.mvc_error_threshold = 1;
% settings.mvc_rms_threshold = 0.01;

%% Create EMG Flag Structure
% removing erroneous EMG data based on previous processing
% load flags structure
load(emgFlagsPath);
flags = flags.SUBJ1;

if(~isempty(flags))
    settings.emg_remove_flags = flags;
end

%% Process MVC Data
[~,flags] = processMVC(settings);

if(~isempty(flags))
    settings.emg_remove_flags = flags;
end

settings.mvc_directory = "SUBJ1/MVCprocessed.mat";

%% Check Static Trial
staticTrials = c3dFiles(contains(c3dFiles,"static","IgnoreCase",true));
settings.grf_static_trial = fullfile(c3dDir, staticTrials(1));
settings.grf_correct_force_plate_idx = 3;
settings.grf_scale = computeGRFcorrection(settings);

%% Process Data
% Loop over .c3d files
f = waitbar(0, 'Processing data...');
for fileIdx = 1:Nfiles
    c3dFile = c3dFiles(fileIdx);
    settings.c3d_path_file = char(fullfile(c3dDir, c3dFile));

    % save events
    [~,fileName,~] = fileparts(c3dFile);
    gaitEvents = readC3Devents(settings);
    events.(fileName) = gaitEvents;
    settings.gaitEvents = gaitEvents;

    waitbar(fileIdx/Nfiles, f, ['Processing file: ' char(replace(c3dFiles(fileIdx),"_"," ")) ' (' num2str(fileIdx) '/' num2str(Nfiles) ')'])

    % estimate virtual markers only for the static trial
    if(contains(fileName,"static","IgnoreCase",true))
        settings.add_hip_virtual_markers = true;
        settings.add_foot_virtual_markers = true;
        settings.add_AJC_virtual_markers = false;
    else
        settings.add_hip_virtual_markers = false;
        settings.add_foot_virtual_markers = false;
        settings.add_AJC_virtual_markers = false;
    end
    readC3D(settings);
end
close(f)

%% Save Events Structure
save(results_directory + "/gaitEvents.mat","events")
