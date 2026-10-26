function settings = runScale(settings)
%% Scale - Create a new model scaled on the subject
% 
% Use an unscaled .osim model file, a generic .xml setting file and parameters to create a new .osim model with the dimension of the subject
%
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% settings                          | struct            | Configuration structure with fields:
%   settings.model_dir              | string            | Path to the directory to store the model
%   settings.xml_scaling_file       | string            | Path to the generic .xml setting file for scaling 
%   settings.unscaled_model_path    | string            | Path to the unscaled .osim model 
%   settings.trc_scaling            | string            | Path to the .trc file for the scaling
%   settings.body_weight            | double            | Optional: Weight of the subject
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
%   settings.scaled_model_path      | string            | Path to the scaled .osim model 
%
%------------------------------------------------------------- NOTES ------------------------------------------------------------
% The generic .xml file is different between Vicon and Xsens
% The .trc file used in scaling has to be stored in model_dir
%
% Original Author: Caroline Laroumagne
% Date: 23/08/25

%% Import
import org.opensim.modeling.*;

%% Showing Log
logFile = 'opensim.log';
Logger.addFileSink(logFile);
Logger.setLevelString('Info');

%% Create output directory
% settings.model_dir = fullfile(settings.results_dir,'MODEL'); %MODEL

if ~exist(settings.model_dir,'dir')
    mkdir(settings.model_dir);
end

%% Retrieve parameter value from settings
model_dir = settings.model_dir;
xml_scaling_file = settings.xml_scaling_file;
unscaled_model_path = settings.unscaled_model_path;
trc_scaling = settings.trc_scaling;

% [~,name,ext] = fileparts(trc_scaling);
% trc_name = strcat('./',name,ext);

if isfield(settings,"model_name")
    name = settings.model_name;
end

%% Fill the generic .xml file
scaleTool = ScaleTool(xml_scaling_file);
scaleTool.setPrintResultFiles(true);

if(isfield(settings,"body_weight"))
    scaleTool.setSubjectMass(settings.body_weight);
end

G = scaleTool.getGenericModelMaker;
G.setModelFileName(unscaled_model_path);

M = scaleTool.getModelScaler;
model = strcat(name,'.osim');
M.setOutputModelFileName(model);
M.setMarkerFileName(trc_scaling);

MarkerPlacer = scaleTool.getMarkerPlacer;
MarkerPlacer.setMarkerFileName(trc_scaling);
MarkerPlacer.setOutputModelFileName(model);

%% Get the time boundaries from the file
if(isfield(settings,"read_trc_time"))
    if(settings.read_trc_time)
        fid = fopen(trc_scaling);
        for i = 1:5
            line = fgetl(fid);
        end
        
        i=1;
        while(~feof(fid))
            line = fgetl(fid);
            values = strsplit(line,'\t');
            for j = 1:length(values)
                data{i,j} = string(values{j});
            end
            i = i+1;
        end
        fclose(fid);
        start_time = data{1,2};
        last_time = data{end,2};
        timeRange = ArrayDouble();
        timeRange.append(str2double(start_time));
        timeRange.append(str2double(last_time));
        MarkerPlacer.setTimeRange(timeRange);
    end
end

scaleTool.setName(char(name));

%% run the scaling
specific_xml = fullfile(model_dir,strcat(name,'.xml'));
scaleTool.print(specific_xml);

completeScaleTool = ScaleTool(specific_xml);

completeScaleTool.run();

model = fullfile(model_dir,strcat(name,'.osim'));
settings.scaled_model_path = model;

type("opensim.log")

end