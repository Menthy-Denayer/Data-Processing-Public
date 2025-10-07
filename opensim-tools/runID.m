function runID(settings)
%% run ID function to run the inverse dynamics tool using the OpenSim API.
%--------------------------------------------INPUTS--------------------------------------------
% settings                              | structure         | list of settings to run the tool
%   settings.model_file                 | string            | model file location
%   settings.mot_file                   | string            | kinematics data location (.mot)
%   settings.grf_file                   | string            | ground reaction forces data location (.sto)
%   settings.xml_file                   | string            | ID settings file location (.xml)
%   settings.grf_setup_file             | string            | setup file for GRFs (.xml)
%   settings.output_dir                 | string            | output directory to save results
%   settings.output_file_name           | string            | optional: output file name 
%   settings.printSettings              | boolean           | optional: whether to print the IK settings file
%   settings.time_range                 | 1x2 double array  | optional: time range for performing ID [start end]
%   settings.lowpass_frequency          | double            | optional: coordinate lowpass frequency filter

%% Import OpenSim Libraries
import org.opensim.modeling.*

%% Define Settings
outputDir = settings.output_dir;
if(~exist(outputDir,"dir"))
    mkdir(outputDir)
end

if(~isfield(settings, "printSettings"))
    settings.printSettings = false;
end

%% Load OpenSim Model
% Load OpenSim file
model = Model(settings.model_file);

%% Remove Ground Contact Force
% Required, otherwise GRFs are counted twice
IDmodel = model.clone();

% Define force set
forceSet = IDmodel.getForceSet();

% Loop through forceset (potentially do backwards?)
for forceIdx = 0:1:forceSet.getSize()-1
    force = forceSet.get(forceIdx);
    if isa(force, 'HuntCrossleyForce') || contains(char(force.getConcreteClassName()), 'Contact')
        fprintf('Removing force: %s\n', char(force.getName()));
        forceSet.remove(forceIdx);
    end
end

%% Create External Loads File
% Create external loads object from template
externalLoads = ExternalLoads(settings.grf_setup_file,true);
% Add grf data
externalLoads.setDataFileName(settings.grf_file);
% Save external loads file
[~,externalLoadsFileName,~] = fileparts(settings.grf_file);                 % extract grf data name
externalLoadsFileName = externalLoadsFileName + "_setup.xml";               % add suffix to results file
externalLoads.print(fullfile(outputDir,externalLoadsFileName));

%% Run inverse dynamics
% Create the inverse dynamics tool
idTool = InverseDynamicsTool(settings.xml_file);

% Exclude muscles from ID analysis
excludedForces = ArrayStr();
excludedForces.append("Muscles");
idTool.setExcludedForces(excludedForces);

% Assign OpenSim model
idTool.setModel(IDmodel);
% idTool.setModelFileName(settings.model_file);

% Assign kinematics coordinate file
idTool.setCoordinatesFileName(settings.mot_file)

% Assign external loads file
idTool.setExternalLoadsFileName(fullfile(outputDir,externalLoadsFileName))

% Set coordinates lowpass frequency
if isfield(settings, "lowpass_frequency")
    fprintf(['Lowpass filtering coordinates at ' num2str(settings.lowpass_frequency) ' Hz\n'])
    idTool.setLowpassCutoffFrequency(settings.lowpass_frequency);
end

% Define output file
if(~isfield(settings, "output_file_name"))
    [~,motFileName,~] = fileparts(settings.mot_file);                       % extract marker data name
    settings.output_file_name = motFileName + "_id.sto";                    % add suffix to results file
end

idTool.setResultsDir(outputDir);
idTool.setOutputGenForceFileName(fullfile(outputDir, settings.output_file_name));

% Set start/end times
if isfield(settings, "time_range")
    fprintf('Found time range for performing ID\n')
    idTool.setStartTime(settings.time_range(1));
    idTool.setEndTime(settings.time_range(2));
end

% Print settings
if(settings.printSettings)
    idTool.print("id_settings.xml");
end

% Run the ID tool
idTool.run();

end