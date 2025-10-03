function computeJointPowers(settings)
%% computeJointPowers - function to compute the total joint powers for the different joints.
% - the function automatically finds the unique joints and sums the powers over all axes
% - we use the time frame from the ID results to compute the joint powers, to make sure the data includes force data
%
%--------------------------------------------INPUTS--------------------------------------------
% settings                              | structure     | list of settings to run the tool
%   settings.ik_mot_file                | string        | path to the IK .mot file
%   settings.scaled_model_path          | string        | path to the (scaled) model
%   settings.analyze_dir                | string        | directory to store the results of the analyze tool
%   settings.analyze_xml_file           | string        | path to the general .xml file for the analyze tool
%   settings.id_sto_file                | string        | path to the ID .sto file
%   settings.power_sto_file             | string        | file name of the output file
%   settings.power_directory            | string        | directory to store the computed joint powers

%% Add Paths
[pathHere,~,~] = fileparts(mfilename('fullpath'));
pathGIT = extractBefore(pathHere,"\o");
addpath(pathGIT + "\data-processing\utilities\")

%% Import OpenSim Libraries
import org.opensim.modeling.*

%% Initialize Settings
if(~isfield(settings,"net_joint_power"))
    settings.net_joint_power = true;
end

%% Run Analyze Tool
% To find the joint angular/linear velocities
runAnalyze(settings);

%% Find joint velocities
[~,ikFile,~] = fileparts(settings.ik_mot_file);
analysisFile = ikFile + "_Kinematics_u.sto";                                % default output name from OpenSim

% extract data
kinData = importdata(fullfile(settings.analyze_dir,analysisFile));
kinTime = kinData.data(:,1);
Ncol = length(kinData.colheaders);

%% Find joint torques
idData = importdata(settings.id_sto_file);
idTime = idData.data(:,1);
Ndata = length(idTime);

%% Match Columns
% name of the joints from ID
idNamesBase = strrep(string(idData.colheaders),"_moment","");               % remove "moment" suffix
idNamesBase = strrep(idNamesBase,"_force","");                              % remove "force" suffix
idNamesBase = idNamesBase(2:end);                                           % remove time

% name of the joints from IK
ikNameBase = string(kinData.colheaders);
ikNameBase = ikNameBase(2:end);

% match the joint names from ID & IK
idIdxs = zeros(Ncol-1,1);                                                   % list to store indices matching the data columns of the kinematics
for i = 1:Ncol-1
    idIdxs(i) = find(idNamesBase == ikNameBase(i))+1;
end

%% Compute joint powers
% find start/end indices for kinematics data, we only use the time range 
% of ID
startIdx = findTimeIdx(kinTime,idTime(1));      
endIdx = findTimeIdx(kinTime,idTime(end));

% compute power
velData = kinData.data(startIdx:endIdx,2:end);                              % angular/linear velocities
forceData = idData.data(:,idIdxs);                                          % joint moments/forces

powerData = zeros(Ndata, Ncol-1);
for powerIdx = 1:Ncol-1
    powerData(:,powerIdx) = velData(:,powerIdx).*forceData(:,powerIdx);     % joint powers (per axis)
end

% correct dimensions
isForce = contains(string(idData.colheaders),"_force");
isForce = isForce(2:end);

isMoment = ~ismember(idIdxs,find(isForce)+1);
% ikNameBase(~isMoment)
powerData(:,isMoment) = powerData(:,isMoment)*pi/180;

%% Debug Plot
% for i = 1:Ncol-1
%     figure
%     hold on
%     plot(forceData(:,i),"red")
%     plot(velData(:,i),"blue")
%     plot(powerData(:,i),'black')
%     title(ikNameBase(i))
%     hold off
% end

%% Find Joints
% combine power over different axes for each unique joint
if(settings.net_joint_power)
    jointNames = strings(Ncol-1,1);
    
    for colIdx = 2:Ncol
        currColName = split(string(kinData.colheaders{colIdx}),"_");
        if(any(currColName == "l"))
            jointNames(colIdx-1) = currColName(1) + "_l";
        elseif(any(currColName == "r"))
            jointNames(colIdx-1) = currColName(1) + "_r";
        else
            jointNames(colIdx-1) = currColName(1);
        end
    end
    
    [jointNames, ~, jointIdxList] = unique(jointNames);
else
    jointNames = string(kinData.colheaders(2:end));
end

%% Combine Powers for same joint
if(settings.net_joint_power)
    Njoints = length(jointNames);
    Ndata = length(idTime);
    jointPowerData = zeros(Ndata, Njoints);
    
    for jointIdx = 1:Njoints
        % jointNames(jointIdx)
        powerIdxs = find(jointIdxList==jointIdx);
        % ikNameBase(powerIdxs)
        jointPowerData(:,jointIdx) = sum(powerData(:,powerIdxs),2);
    end
else
    jointPowerData = powerData;
end

%% Debug
% for jointIdx = 1:Njoints
%     figure
%     hold on
%     grid on
%     plot(idTime, jointPowerData(:,jointIdx), "red", LineWidth=1)
%     xlim([idTime(1), idTime(end)])
%     title(jointNames(jointIdx))
%     hold off
% end

%% Save Results
% Define output file
if(~isfield(settings, "power_sto_file"))
    [~,motFileName,~] = fileparts(settings.ik_mot_file);                    % extract IK data name
    settings.power_sto_file = strrep(motFileName,"_ik","_power.sto");                 % add suffix to results file
end

if(~isfield(settings,"power_directory"))
    settings.power_directory = "";
else
    % check if the directory already exists
    if(~exist(settings.power_directory,"dir"))
        mkdir(settings.power_directory);
    end
end

jointNames = jointNames + "_power";
powerTable = createTimeSeriesTable(jointNames, idTime, jointPowerData);
STOFileAdapter().write(powerTable, fullfile(settings.power_directory, settings.power_sto_file));
disp(['Processed power data written to: ' char(settings.power_sto_file)]);

end

%% Save results
function idx = findTimeIdx(timeVector, timePoint)
    [dist,idx] = min(abs(timeVector-timePoint));
    if(dist > 0.5)
        warning(['Time distance is larger than 0.5 (' num2str(dist) ')!'])
        idx = 1;
    end
end