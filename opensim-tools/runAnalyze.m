function runAnalyze(settings)
%% runAnalyze - Run the Analyze Tool using the OpenSim API
%
% Add more parameters to the generic .xml analyze file and run the Analyze Tool with those specifications
%
% -----------------------------INPUT---------------------------------------
% settings                          | structure     | list of settings to run the tool
%   settings.ik_mot_file            | string        | path to the IK .mot file
%   settings.scaled_model_path      | string        | path to the model
%   settings.analyze_dir            | string        | directory to store the results of the analyze
%   settings.analyze_xml_file       | string        | path to the general .xml file for the Analyze Tool
%
% 
% Original Author : Caroline Laroumagne
% Date : 21/08/25

%% Import
import org.opensim.modeling.*;

%% Get settings parameters
analyze_xml_file = settings.analyze_xml_file;
model_file = settings.scaled_model_path;
ik_mot_file = settings.ik_mot_file;
analyze_dir = settings.analyze_dir;
if(~exist(analyze_dir,"dir"))
    mkdir(analyze_dir)
end

%% Changes on the generic .xml file
OpenSimModel= Model(model_file);
aTool = AnalyzeTool(analyze_xml_file,false);

[~,name,~] = fileparts(ik_mot_file);
aTool.setName(name);

aTool.setModel(OpenSimModel);
aTool.setModelFilename(model_file);

aTool.setResultsDir(analyze_dir);

aTool.setCoordinatesFileName(ik_mot_file);

% Get the start_time and the end_time
[start_time,end_time] = get_time(ik_mot_file);

aTool.setInitialTime(start_time);
aTool.setFinalTime(end_time);

analysisSet = aTool.getAnalysisSet();
for i = 0:analysisSet.getSize()-1
    analysis = analysisSet.get(i);
    analysis.setStartTime(start_time);
    analysis.setEndTime(end_time);
end

output_path = fullfile(analyze_dir,[name '_specific_analyze.xml']);
aTool.print(output_path);

%% Use of the new file to run the AnalyzeTool
A = AnalyzeTool(output_path);

A.run();
end