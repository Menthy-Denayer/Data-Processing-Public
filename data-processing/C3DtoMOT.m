function [mot_file, forceTableProcessed] = C3DtoMOT(settings, OpenSimC3D)
%% C3DtoMOT - Converts ground reaction forces from .c3D to OpenSim .mot format
% - Renames force labels for OpenSim GUI compatibility.
% - Handles NaN values in the force data via linear interpolation.
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% settings                              | struct                | Configuration structure with fields:
%   settings.c3d_path_file              | string                | Full path to the .c3d input file
%   settings.use_COP_as_moments_point   | integer (0, 1, 2)     | Use Center of Pressure as reference for moments (default = 1)
%   settings.mot_results_dir            | string                | Path to save the resulting .mot file
%   settings.desired_forces             | Nx1 integer array     | optional: list of desired forces (indices)
%   settings.forces_lowpassFilter       | boolean               | optional: lowpass filter the force data
%   settings.forces_threshold           | double                | optional: threshold for vertical GRF to be non-zero
%   settings.forces_lowpassFreq         | double                | optional: lowpass frequency limit 
%   settings.forces_lowpassFilterOrder  | integer               | optional: lowpass filter order
% OpenSimC3D                            | OpenSim C3D object    | C3D object with force data
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% mot_file                              | string                | Full path to the generated .mot file
% forceTableProcessed                   | Osim TimeSeries Table | Table containing the processed force data
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% OpenSim MATLAB API (osimC3D)          | https://github.com/opensim-org/opensim-core/blob/main/Bindings/Java/Matlab/Utilities/osimC3D.m
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Couëdel Romane
% Date: 19/May/2025

% Last Update: Menthy Denayer
% Date: 20/Aug/2026 : Fixed accidental time vector filtering

%% Import OpenSim Java Libraries
import org.opensim.modeling.*

%% Add Utilities
[pathHere,~,~] = fileparts(mfilename('fullpath'));
addpath(fullfile(pathHere,"utilities"));

%% Define output file names
[~, filename, ~] = fileparts(settings.c3d_path_file);

switch settings.use_COP_as_moments_point
    case 0
        forcesFilename = strcat(filename, '_forces_EC.mot');
    case 1
        forcesFilename = strcat(filename, '_forces_COP.mot');
end

mot_file = fullfile(settings.mot_results_dir, forcesFilename);

%% Load and Process C3D File
% Create osimC3D object and prepare data
OpenSimC3D.convertMillimeters2Meters();         % Convert data to meters

%% Get Force Data
forceTable = OpenSimC3D.getTable_forces();
forceLabels = forceTable.getColumnLabels();

%% Update Column Labels to OpenSim Conventions
updlabels = forceLabels;
for dataIdx = 0 : forceLabels.size() - 1
    label = char(forceLabels.get(dataIdx));
    if contains(label, 'f')
        label = strrep(label, 'f', 'ground_force_');
        label = [label '_v'];
    elseif contains(label, 'p')
        label = strrep(label, 'p', 'ground_force_');
        label = [label '_p'];
    elseif contains(label, 'm')
        label = strrep(label, 'm', 'ground_moment_');
        label = [label '_m'];
    end
    updlabels.set(dataIdx, label);
end

forceTable.setColumnLabels(updlabels);

%% Flatten the Force Table (Vec3 -> columns)
postfix = StdVectorString();
postfix.add('x'); postfix.add('y'); postfix.add('z');
forceTableFlat = forceTable.flatten(postfix);

% Fix labels
forceLabelsUpd = split(replace(replace(string(updlabels),"[",""),"]",""),", ");
forceLabelsFlat = repelem(forceLabelsUpd,3)' + repmat(["x","y","z"],1,length(forceLabelsUpd));

%% Extract Desired Forces
forceStructFiltered = osimTableToStruct(forceTableFlat);

if isfield(settings,"desired_forces")
    forceNumbers = settings.desired_forces;
    Nforces = length(forceNumbers);
    includedIndices = contains(forceLabelsFlat,string(forceNumbers));
    excludedFields = forceLabelsFlat(~includedIndices);
    forceStructFiltered = rmfield(forceStructFiltered,excludedFields);
else
    length(forceLabelsFlat);
    Nforces = (length(forceLabelsFlat))/9;
    forceNumbers = 1:Nforces;
end

%% Interpolate Missing Values (Linearly)
forceStructCleaned = forceStructFiltered;
forceLabelsFiltered = string(fieldnames(forceStructCleaned));

% loop over force data in structure to interpolate
for forceIdx = 1:length(forceLabelsFiltered)
    forceData = forceStructCleaned.(forceLabelsFiltered(forceIdx));
    forceDataInterpolate = fillmissing(forceData,"linear",1,"EndValues","nearest");
    forceStructCleaned.(forceLabelsFiltered(forceIdx)) = forceDataInterpolate;
end

%% Extract Period Where GRFy > threshold
% Data is set to NaN when GRFy < threshold. This allows for correct 
% filtering later one, preventing edge effects & smoothing.
forceStructZeroed = forceStructCleaned;                                     % create new structure

if ~isfield(settings, "forces_threshold")                                   % check settings
    settings.forces_threshold = 30;                                         % N, default threshold
end

% find indices for vertical GRF forces
GRFyIndices = find(contains(forceLabelsFiltered,"vy"))';
forceNumbers_sorted = sort(forceNumbers);
    
% loop over vertical GRF data
for forceIdx = 1:length(GRFyIndices)
    % find GRFy data
    GRFyIndex = GRFyIndices(forceIdx);
    % GRFyLabel = forceLabelsFiltered(GRFyIndex);
    GRFyData = forceStructZeroed.(forceLabelsFiltered(GRFyIndex));

    % find indices where GRFy data < threshold
    belowThresholdIndices = GRFyData < settings.forces_threshold;

    % set values to zero where GRFy data < threshold for all data
    Nforce = string(forceNumbers_sorted(forceIdx));                         % number of the force data (1-->Nforces)

    dataLabels = forceLabelsFiltered(contains(forceLabelsFiltered,Nforce)); % find data labels for matching GRFy
    for dataIdx = 1:length(dataLabels)
        rawData = forceStructZeroed.(dataLabels(dataIdx));
        zeroedData = rawData; zeroedData(belowThresholdIndices) = NaN;      % set data to NaN when below threshold
        % if(contains(dataLabels(dataIdx),"vy"))
        %     zeroedData(belowThresholdIndices) = 0;
        % end
        forceStructZeroed.(dataLabels(dataIdx)) = zeroedData;
    end
end

%% Lowpass Filter GRF Data
forceStructLowpass = forceStructZeroed;                                     % create new structure

if ~isfield(settings, "forces_lowpassFilter")                               % check settings
    settings.forces_lowpassFilter = true;
end

if(settings.forces_lowpassFilter)

    % read lowpass filter settings
    lowpassSettings = struct([]);
    if isfield(settings,"forces_lowpassFreq")
        lowpassSettings(1).lowpassFreq = settings.forces_lowpassFreq;
    end
    
     if isfield(settings,"forces_lowpassFilterOrder")
        lowpassSettings(1).lowpassFilterOrder = settings.forces_lowpassFilterOrder;
    end

    FS = OpenSimC3D.getRate_force();                                        % get sampling frequency
    
    % loop over force data in structure to lowpass filter
    for forceIdx = 1:length(forceLabelsFiltered)
        forceLabel = forceLabelsFiltered(forceIdx);
        if(~contains(forceLabel,"time"))
            forceData = forceStructLowpass.(forceLabel);
            forceDataLowpass = lowpassFilter(forceData, FS, lowpassSettings);   % lowpass filter data
            forceStructLowpass.(forceLabel) = forceDataLowpass;
        end
    end
end

% for forceIdx = 1:length(forceLabelsFiltered)
%     figure
%     hold on
%     forceLabel = forceLabelsFiltered(forceIdx);
%     forceData = forceStructLowpass.(forceLabel);
%     plot(forceData)
%     title(forceLabel)
%     hold off
% end

%% Put NaN to Zero for GRFy
for forceIdx = 1:length(forceLabelsFiltered)
    forceLabel = forceLabelsFiltered(forceIdx);
    if(contains(forceLabel,"vy"))
        forceData = forceStructLowpass.(forceLabel);
        newData = forceData;
        newData(isnan(forceData)) = 0;
        forceStructLowpass.(forceLabel) = newData;
    end
end

%% Corrective Scaling
if(isfield(settings,"grf_scale"))
    forcePlateFields = forceLabelsFiltered(contains(forceLabelsFiltered,string(settings.grf_correct_force_plate_idx)));
    isForce = contains(forcePlateFields,"_v");
    isMoment = contains(forcePlateFields,"moment");
    forcePlateFields = forcePlateFields(isForce | isMoment);
    Nfields = length(forcePlateFields);
    for fieldIdx = 1:Nfields
        forceStructLowpass.(forcePlateFields(fieldIdx)) = forceStructLowpass.(forcePlateFields(fieldIdx))*settings.grf_scale;
    end
end

%% Extract Foot Order (Left/Right)
% If gait events are given, find left/right order for walking
if isfield(settings,"gaitEvents")
    Ndata = size(forceStructLowpass.("time"),1);                            % number of data points
    vy_ordered = zeros(Ndata, Nforces+1);                                   % vertical force in order of force plate hits
    vy_ordered(:,1) = forceStructLowpass.("time");                          % time vector
    
    % Loop over forces
    for forceIdx = 1:Nforces
        vyIdx = contains(forceLabelsFiltered, forceNumbers(forceIdx) + "_vy");
        vy_ordered(:,forceIdx+1) = forceStructLowpass.(forceLabelsFiltered(vyIdx));
    end
    LRorder = extractForcePlateOrder(settings, vy_ordered);                 % extract left/right order
else
    LRorder = ["r" "l"]; % temp
end

%% Combine Forces (Left/Right)
% To run ID etc. OpenSim excpects one delimiter for the right/left data.
NgrfData = 9;                                                               % GRF, COP, GRM

grfLabels_1 = ["ground_force_" + LRorder(1) + "_" + ["vx", "vy", "vz", "px", "py", "pz"], "ground_moment_" + LRorder(1) + "_" + ["mx", "my", "mz"]];
grfLabels_2 = strrep(grfLabels_1,"_"+LRorder(1)+"_","_"+LRorder(2)+"_");

forceLabelsCombined = forceLabelsFiltered;
forceStructCombined = struct([]);                                           % create new structure

% extract indices to combine taking into account order of desired forces
forceNumbers_1 = sort(forceNumbers(1:2:end))-min(forceNumbers)+1;
indices_1 = zeros(length(forceNumbers_1)*NgrfData,1);
for forceIdx = 1:length(forceNumbers_1)
    indices_1(1+(forceIdx-1)*NgrfData:forceIdx*NgrfData) = 1+NgrfData*(forceNumbers_1(forceIdx)-1):NgrfData*(forceNumbers_1(forceIdx)-1)+NgrfData;
end
forceNumbers_2 = sort(forceNumbers(2:2:end))-min(forceNumbers)+1;
indices_2 = zeros(length(forceNumbers_2)*NgrfData,1);
for forceIdx = 1:length(forceNumbers_2)
    indices_2(1+(forceIdx-1)*NgrfData:forceIdx*NgrfData) = 1+NgrfData*(forceNumbers_2(forceIdx)-1):NgrfData*(forceNumbers_2(forceIdx)-1)+NgrfData;
end

% Loop over first set of GRF data
for forceIdx = 1:NgrfData
    combineIdx_1 = indices_1(forceIdx):NgrfData:indices_1(end);
    forceStructCombined(1).(grfLabels_1(forceIdx)) = 0;

    for fieldIdx = combineIdx_1
        forceData = forceStructLowpass.(forceLabelsCombined(fieldIdx));     % extract force data to combine
        forceData(isnan(forceData)) = 0;                                    % remove NaNs (replace by zero)
        forceStructCombined.(grfLabels_1(forceIdx)) = ...                   % add data together
            forceStructCombined.(grfLabels_1(forceIdx)) + forceData;
    end
end

% Loop over second set of GRF data
for forceIdx = 1:NgrfData
    combineIdx_2 = indices_2(forceIdx):NgrfData:indices_2(end);
    forceStructCombined(1).(grfLabels_2(forceIdx)) = 0;

    for fieldIdx = combineIdx_2
        forceData = forceStructLowpass.(forceLabelsCombined(fieldIdx));     % extract force data to combine
        forceData(isnan(forceData)) = 0;                                    % remove NaNs (replace by zero)
        forceStructCombined.(grfLabels_2(forceIdx)) = ...                   % add data together
            forceStructCombined.(grfLabels_2(forceIdx)) + forceData;
    end
end

forceStructCombined(1).("time") = forceStructLowpass.("time");              % add time to new structure

%% Write to .mot File
forceTableProcessed = osimTableFromStruct(forceStructCombined);
STOFileAdapter().write(forceTableProcessed, mot_file);
disp(['Processed force data written to: ' char(mot_file)]);

end
