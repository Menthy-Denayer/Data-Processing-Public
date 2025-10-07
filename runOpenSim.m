clear all
clc
close all

%% Add Path
addpath("opensim-tools");
addpath("opensim-tools\utilities");
addpath("data-processing\utilities");

%% Define Variables
runIKcode = true;
runIDcode = true;
runPowercode = true;
runBKcode = true;

%% Load OpenSim Model
% Load model file
[osim_file_name, osim_data_loc] = uigetfile("*.osim","Select .osim model file.");

%% Choose OpenSim Weighted Model Directory
weightedModelDir = uigetdir("","Choose weighted model directory.");
dirInfo = struct2table(dir(weightedModelDir));
[~,~,fileExtensions] = fileparts(dirInfo.name);
weightedModelFiles = string(dirInfo.name(ismember(fileExtensions, ".osim"))); 

modelFiles = [string(osim_file_name) osim_data_loc;
    weightedModelFiles repmat(weightedModelDir,5,1)];

%% Choose TRC Directory
trcDir = uigetdir("","Choose directory with .trc files to process");
dirInfo = struct2table(dir(trcDir));
[~,~,fileExtensions] = fileparts(dirInfo.name);
trcFiles = string(dirInfo.name(ismember(fileExtensions, ".trc")));
Nfiles = length(trcFiles);  

%% Choose GRF Directory
grfDir = uigetdir("","Choose directory with GRF .mot files to process");
dirInfo = struct2table(dir(grfDir));
[~,~,fileExtensions] = fileparts(dirInfo.name);
grfFiles = string(dirInfo.name(ismember(fileExtensions, ".mot")));
NGRFfiles = length(grfFiles);  

%% Select Data Files
% Load IK settings file
[IKxml_file_name, IKxml_data_loc] = uigetfile("*.xml","Select IK .xml settings file.");

% Load ID settings file
[IDxml_file_name, IDxml_data_loc] = uigetfile("*.xml","Select ID .xml settings file.");

% Load grf setup file
[grf_setup_file_name, grf_setup_data_loc] = uigetfile("*.xml","Select .xml ground reaction forces setup file.");

% Load Analysis file (joint powers)
[POWERxml_file_name, POWERxml_data_loc] = uigetfile("*.xml","Select analysis (joint powers) .xml settings file.");

% Load Analysis file (body kinematics)
[BKxml_file_name, BKxml_data_loc] = uigetfile("*.xml","Select analysis (body kinematics) .xml settings file.");

% Load gait event file (file containing heel strike events for both legs)
[mat_file_name, mat_file_loc] = uigetfile(".mat","Choose .mat file to process");
gaitEvents = load(fullfile(mat_file_loc,mat_file_name));

%% Define IK Settings
IKsettings.scaled_model_path = fullfile(osim_data_loc, osim_file_name);
IKsettings.xml_ik_file = fullfile(IKxml_data_loc, IKxml_file_name);
IKsettings.ik_mot_dir = fullfile(pwd,"SUBJ01\IK");
IKsettings.reportMarkerErrors = true;
IKsettings.printSettings = true;

%% Define ID Settings
IDsettings.model_file = fullfile(osim_data_loc, osim_file_name);
IDsettings.xml_file = fullfile(IDxml_data_loc, IDxml_file_name);
IDsettings.grf_setup_file = fullfile(grf_setup_data_loc, grf_setup_file_name);
IDsettings.output_dir = fullfile(pwd,"SUBJ01\ID");
IDsettings.printSettings = true;
IDsettings.lowpass_frequency = 6;                                           % Hz

%% Define Analysis Settings (Joint Powers)
POWERsettings.scaled_model_path = fullfile(osim_data_loc, osim_file_name);          
POWERsettings.analyze_dir = fullfile(pwd,'SUBJ01\ANALYSIS');             
POWERsettings.analyze_xml_file = fullfile(POWERxml_data_loc, POWERxml_file_name);    
POWERsettings.power_directory = POWERsettings.analyze_dir;

%% Define Analysis Settings (Body Kinematics)
BKsettings.scaled_model_path = fullfile(osim_data_loc, osim_file_name);          
BKsettings.analyze_dir = fullfile(pwd,'SUBJ01\ANALYSIS');             
BKsettings.analyze_xml_file = fullfile(BKxml_data_loc, BKxml_file_name);    

%% Run IK
if(runIKcode)
    f = waitbar(0, 'Starting IK...');
    for fileIdx = 1:Nfiles
        waitbar(fileIdx/Nfiles, f, ['Processing file ' num2str(fileIdx) '/' num2str(Nfiles)])
        IKsettings.trc_file = fullfile(trcDir, trcFiles(fileIdx));
        runIK(IKsettings)
    end
    close(f)
end

%% Find IK Results
dirInfo = struct2table(dir(IKsettings.ik_mot_dir));
[~,~,fileExtensions] = fileparts(dirInfo.name);
motFiles = string(dirInfo.name(ismember(fileExtensions, ".mot")));
NIKfiles = length(motFiles); 

%% Run ID
if(runIDcode)
    f = waitbar(0, 'Starting ID...');
    for fileIdx = 1:NIKfiles
        waitbar(fileIdx/NIKfiles, f, ['Processing file ' num2str(fileIdx) '/' num2str(NIKfiles)])
    
        % select files
        IDsettings.mot_file = fullfile(IKsettings.ik_mot_dir, motFiles(fileIdx));
        IDsettings.grf_file = fullfile(grfDir, grfFiles(fileIdx));
    
        % choose model
        IDsettings.model_file = select_model(modelFiles, IDsettings.mot_file);
        [~,modelName,~] = fileparts(IDsettings.model_file);
        fprintf(['Using model: ' char(modelName) '\n'])
    
        % extract time range
        [~,fileName,~] = fileparts(motFiles(fileIdx));
        fileName = replace(fileName,"_markers_ik","");
        IDsettings.time_range = extractTimeRange(IDsettings.grf_file, gaitEvents.events.(fileName));
    
        % run ID
        runID(IDsettings)
    end
    close(f)
end

%% Find ID Results
dirInfo = struct2table(dir(IDsettings.output_dir));
[~,~,fileExtensions] = fileparts(dirInfo.name);
idFiles = string(dirInfo.name(ismember(fileExtensions, ".sto")));
NIDfiles = length(idFiles); 

%% Compute Joint Powers
if(runPowercode)
    f = waitbar(0, 'Computing joint powers...');
    for fileIdx = 1:NIDfiles
        waitbar(fileIdx/NIDfiles, f, ['Processing file ' num2str(fileIdx) '/' num2str(NIDfiles)])
    
        % select files
        POWERsettings.ik_mot_file = char(fullfile(IKsettings.ik_mot_dir, motFiles(fileIdx)));
        POWERsettings.id_sto_file = fullfile(IDsettings.output_dir, idFiles(fileIdx));
    
        % compute joint powers
        computeJointPowers(POWERsettings)
    end
    close(f)
end

%% Compute CalcnL/R Origin 
if(runBKcode)
    f = waitbar(0, 'Performing body kinematics...');
    for fileIdx = 1:NIKfiles
        waitbar(fileIdx/NIKfiles, f, ['Processing file ' num2str(fileIdx) '/' num2str(NIKfiles)])
    
        % select files
        BKsettings.ik_mot_file = char(fullfile(IKsettings.ik_mot_dir, motFiles(fileIdx)));
    
        % compute joint powers
        runAnalyze(BKsettings);
    end
    close(f)
end

%% Helper Functions
% extract time range 
% heel strike on second force plate to just before heel strike of same foot
function time_range = extractTimeRange(grf_file, events)
    % import grf data
    GRFstruct = importdata(grf_file);
    GRFcolumns = GRFstruct.colheaders;
    secondForcePlateLabel = GRFcolumns(end);
    if(contains(secondForcePlateLabel,"_l_"))
        time_range = events.LHeelStrike;
    else
        time_range = events.RHeelStrike;
    end
end

function model_file = select_model(modelFiles, motFile)
% assumes modelFiles contains model names in the first column and 
% directories in the 2nd one, organized from normal to 5kg.
    if(contains(motFile,"normal","IgnoreCase",true))
        idx = 1;
    elseif(contains(motFile,"1kg","IgnoreCase",true))
        idx = 2;
    elseif(contains(motFile,"2kg","IgnoreCase",true))
        idx = 3;
    elseif(contains(motFile,"3kg","IgnoreCase",true))
        idx = 4;
    elseif(contains(motFile,"4kg","IgnoreCase",true))
        idx = 5;
    elseif(contains(motFile,"5kg","IgnoreCase",true))
        idx = 6;
    end

    model_file = fullfile(modelFiles(idx, 2),modelFiles(idx, 1));
end