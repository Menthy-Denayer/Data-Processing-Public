function runIK(settings)
%% run IK function to run the inverse kinematics tool using the OpenSim API.
%--------------------------------------------INPUTS--------------------------------------------
% settings                              | structure     | list of settings to run the tool
%   settings.scaled_model_path          | string        | model file location
%   settings.trc_file                   | string        | marker data location (.trc)
%   settings.xml_ik_file                | string        | IK settings file location (.xml)
%   settings.ik_mot_dir                 | string        | output directory to save results (.mot)
%   settings.output_file_name           | string        | optional: output file name 
%   settings.reportMarkerLocations      | boolean       | optional: whether to save the marker locations
%   settings.reportMarkerErrors         | boolean       | optional: whether to save the marker errors
%   settings.printSettings              | boolean       | optional whether to print the IK settings file

%% Import OpenSim Libraries
import org.opensim.modeling.*

%% Define Settings
outputDir = settings.ik_mot_dir;
[~,trcFileName,~] = fileparts(settings.trc_file);                           % extract marker data name

if(~isfield(settings,"reportMarkerLocations"))
    settings.reportMarkerLocations = false;
end

if(~isfield(settings,"reportMarkerErrors"))
    settings.reportMarkerErrors = false;
end

if(~isfield(settings,"printSettings"))
    settings.printSettings = false;
end

%% Load OpenSim Model
% Load model file
OpenSimModel = Model(settings.scaled_model_path);

%% Create Inverse Kinematics Tool
% Create IK tool with predefined settings (.xml)
ikTool = InverseKinematicsTool(settings.xml_ik_file);
ikTool.setName(trcFileName)

% Assign model file
ikTool.setModel(OpenSimModel);
ikTool.set_model_file(settings.scaled_model_path);

% Assign marker data
ikTool.setMarkerDataFileName(settings.trc_file);

% Define output file
if(~isfield(settings,"output_file_name"))
    settings.output_file_name = trcFileName + "_ik.mot";                    % add suffix to results file
end

ikTool.setResultsDir(outputDir);
ikTool.setOutputMotionFileName(fullfile(outputDir, settings.output_file_name));

% Choose whether marker locations are reported
ikTool.set_report_marker_locations(settings.reportMarkerLocations);

% Choose whether to report marker errors
ikTool.set_report_errors(settings.reportMarkerErrors);

% Print settings
if(settings.printSettings)
    ikTool.print(fullfile(outputDir,trcFileName + "_ik_settings.xml"));
end

% Run IK tool
ikTool.run();
end