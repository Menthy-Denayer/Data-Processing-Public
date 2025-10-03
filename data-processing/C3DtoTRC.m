function [trc_file, markerTableProcessed] = C3DtoTRC(settings, OpenSimC3D)
%% C3DtoTRC - Converts marker data from a .c3d file to an OpenSim-compatible .trc file.
% - Handles interpolation of the marker data.
% - Writes a clean .trc file that is OpenSim-compatible.
% - Generates a copy of the original .trc file.
% - Removes columns that do not contain marker data (e.g. angles, moments)

%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% settings                              | struct                | Configuration structure with fields:
%   settings.c3d_path_file              | string                | Full path to the .c3d input file
%   settings.trc_results_dir            | string                | Path to save the resulting .trc file
%   settings.desired_markers            | Nx1 string arrary     | optional: name of markers to extract
%   settings.marker_dictionary          | dictionary            | optional: rename markers inside dictionary
%   settings.markers_lowpassFilter      | boolean               | optional: lowpass filter the marker data
%   settings.markers_lowpassFreq        | double                | optional: lowpass frequency limit 
%   settings.markers_lowpassFilterOrder | integer               | optional: lowpass filter order
%   settings.markers_max_gap            | double                | optional: max gap size to interpolate
%   settings.add_hip_virtual_markers    | boolean               | optional: estimate virtual hip markers
%   settings.add_foot_virtual_markers   | boolean               | optional: estimate virtual foot markers
% OpenSimC3D                            | OpenSim C3D object    | C3D object with marker data
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% trc_file                              | string                | Full path to the generated .mot file
% markerTableProcessed                  | Osim TimeSeries Table | Table containing the processed marker data
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% OpenSim MATLAB API (osimC3D)          | https://github.com/opensim-org/opensim-core/blob/main/Bindings/Java/Matlab/Utilities/osimC3D.m
%
%------------------------------------------------------------ TO DO's -------------------------------------------------------------
% 
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Couëdel Romane
% Date: 19/May/2025

% Last Update: Menthy Denayer
% Date: 28/June/2025 : Added max gap fil threshold to stop markers from staying in one place for long time

%% Import OpenSim Java Libraries
import org.opensim.modeling.*

%% Add Utilities
[pathHere,~,~] = fileparts(mfilename('fullpath'));
addpath(fullfile(pathHere,"utilities"));

%% Define Output File Name
[~, filename, ~] = fileparts(settings.c3d_path_file);
trc_file = fullfile(settings.trc_results_dir, strcat(filename, '_markers.trc'));

%% Extract Marker & Forces Table
markerTable = OpenSimC3D.getTable_markers();

% Extract marker table metadata
markerMetaDataKeys = string(markerTable.getTableMetaDataKeys().toArray());
markerMetaDataValues = strings(length(markerMetaDataKeys),1);
for keyIdx = 1:length(markerMetaDataKeys)
    try 
        markerMetaDataValues(keyIdx) = markerTable.getTableMetaDataString(markerMetaDataKeys(keyIdx));
    catch ME
        warning(ME.identifier, 'Error when extracting marker meta data for key: %s', markerMetaDataKeys(keyIdx));
    end
end

%% Filter Marker Data
markerTableFiltered = markerTable.clone();
markerLabels = string(markerTable.getColumnLabels());
markerLabels = split(replace(replace(markerLabels,"[",""),"]",""),", ");

% filter desired markers
if isfield(settings, 'desired_markers')
    excludedIndices = find(~ismember(markerLabels, settings.desired_markers));
% remove data other than markers
else
    excludedKeyWords = ["Power", "Moment", "Force", "GRF", "Angle", "CentreOfMass", "*"];
    excludedIndices = find(contains(markerLabels, excludedKeyWords, 'IgnoreCase', true));
end

% remove excluded data
for i = length(excludedIndices):-1:1
    markerTableFiltered.removeColumnAtIndex(excludedIndices(i)-1);
end

%% Interpolate Missing Values (Linearly)
% Check if setting exists for max gap filling
if ~isfield(settings, 'markers_max_gap')
    settings.markers_max_gap = 20;                                          % default: max 20 frames
end

markerStructFiltered = osimTableToStruct(markerTableFiltered);
markerLabelsFiltered = string(fieldnames(markerStructFiltered));

markerStructCleaned = markerStructFiltered;                                 % create new structure

for markerIdx = 1:length(markerLabelsFiltered)
    markerData = markerStructFiltered.(markerLabelsFiltered(markerIdx));
    markerDataCleaned = fillmissing(markerData,"spline",1,"EndValues","none","MaxGap",settings.markers_max_gap);
    markerStructCleaned.(markerLabelsFiltered(markerIdx)) = markerDataCleaned;
end

%% Lowpass Filter Marker Data
markerStructLowpass = markerStructCleaned;                                  % create new structure

if ~isfield(settings, "markers_lowpassFilter")                              % check settings
    settings.markers_lowpassFilter = false;
end

if(settings.markers_lowpassFilter)

    % read lowpass filter settings
    lowpassSettings = struct([]);
    if isfield(settings,"markers_lowpassFreq")
        lowpassSettings(1).lowpassFreq = settings.markers_lowpassFreq;
    end
    
    if isfield(settings,"forces_lowpassFilterOrder")
        lowpassSettings(1).markers_lowpassFilterOrder = settings.markers_lowpassFilterOrder;
    end

    FS = OpenSimC3D.getRate_marker();                                       % get sampling frequency
    
    % loop over force data in structure to lowpass filter
    for markerIdx = 1:length(markerLabelsFiltered)
        markerLabel = markerLabelsFiltered(markerIdx);
        markerData = markerStructLowpass.(markerLabel);
        markerDataLowpass = lowpassFilter(markerData, FS, lowpassSettings); % lowpass filter data
        markerStructLowpass.(markerLabel) = markerDataLowpass;
    end
end

%% Add Hip Virtual Markers
if(~isfield(settings,"add_hip_virtual_markers"))
    settings.add_hip_virtual_markers = false;
end

% compute virtual hip markers
if(settings.add_hip_virtual_markers)

    % find ASIS, PSIS and HJC markers
    pelvisMarkerNames = ["RASI", "LASI", "RPSI", "LPSI", "RHJC", "LHJC"];
    NpelvisMarkers = length(pelvisMarkerNames);

    % check if one of PSI markers present (L or R)
    % estimate other one for static trial
    % (same X/Y, mirrored Z)
    if(sum(contains(markerLabelsFiltered,"PSI")) == 1)
        PSIidx = contains(markerLabelsFiltered,"PSI");
        PSIdata = markerStructLowpass.(markerLabelsFiltered(PSIidx));
        SACRdata = markerStructLowpass.("SACR");
        shift = PSIdata(:,3) - SACRdata(:,3);
        newPSIdata = PSIdata; newPSIdata(:,3) = newPSIdata(:,3)-2*shift;         % switch z-coordinate
        newPSIdata(any(isnan(SACRdata),2),:) = NaN;
        PSIside = strrep(markerLabelsFiltered(PSIidx),"PSI","");
        if(PSIside == "R")
            newPSIside = "L";
        else
            newPSIside = "R";
        end
        markerLabelsFiltered = [markerLabelsFiltered; newPSIside + "PSI"];
        markerStructLowpass.(newPSIside + "PSI") = newPSIdata;
        warning(['Only ' char(PSIside) 'PSI marker found. Estimated ' char(newPSIside + "PSI") ' by mirroring around SACR marker.'])
    end
    
    % check available markers
    [~,colIdx] = ismember(pelvisMarkerNames, markerLabelsFiltered); colIdx = colIdx(colIdx>0);

    if(length(colIdx) ~= NpelvisMarkers)
        warning(['Not all required pelvis markers were found. Check naming and joint centres! Found markers are: ' char(strjoin(markerLabelsFiltered(colIdx),", "))])
    else
        % extract ASIS, PSIS and HJC marker data
        Ndata = length(markerStructLowpass.time);
        pelvisMarkerData = zeros(Ndata,3,NpelvisMarkers);
        for markerIdx = 1:NpelvisMarkers
            pelvisMarkerData(:,:,markerIdx) = markerStructLowpass.(pelvisMarkerNames(markerIdx));
        end

        % compute virtual markers
        [virtualMarkerLabels, virtualMarkerData] = computePelvisVirtualMarkers(pelvisMarkerNames, pelvisMarkerData);

        % add markers to table
        NvirtualMarkers = length(virtualMarkerLabels);
        for markerIdx = 1:NvirtualMarkers
            markerStructLowpass.(virtualMarkerLabels(markerIdx)) = virtualMarkerData(:,:,markerIdx);
        end
        markerLabelsFiltered = string(fieldnames(markerStructLowpass));
    end
end

%% Add AJC Virtual Markers
if(~isfield(settings,"add_AJC_virtual_markers"))
    settings.add_AJC_virtual_markers = false;
end

% compute virtual hip markers
if(settings.add_AJC_virtual_markers)

    % find AJC, MT5 and TOE markers
    ankleMarkerNames = ["RANK", "LANK", "RANKmed", "LANKmed"];
    NankleMarkers = length(ankleMarkerNames);
    [~,colIdx] = ismember(ankleMarkerNames, markerLabelsFiltered); colIdx = colIdx(colIdx>0);

    if(length(colIdx) ~= NankleMarkers)
        warning(['Not all required ankle markers were found. Check naming! Found markers are: ' char(strjoin(markerLabelsFiltered(colIdx),", "))])
    else
        % extract ankle marker data
        Ndata = length(markerStructLowpass.time);
        footMarkerData = zeros(Ndata,3,NankleMarkers);
        for markerIdx = 1:NankleMarkers
            footMarkerData(:,:,markerIdx) = markerStructLowpass.(ankleMarkerNames(markerIdx));
        end

        % compute virtual markers
        [virtualMarkerLabels, virtualMarkerData] = computeAJC(ankleMarkerNames, footMarkerData);

        % add markers to table
        NvirtualMarkers = length(virtualMarkerLabels);
        for markerIdx = 1:NvirtualMarkers
            markerStructLowpass.(virtualMarkerLabels(markerIdx)) = virtualMarkerData(:,:,markerIdx);
        end
        markerLabelsFiltered = string(fieldnames(markerStructLowpass));
    end
end

%% Add Foot Virtual Markers
if(~isfield(settings,"add_foot_virtual_markers"))
    settings.add_foot_virtual_markers = false;
end

% compute virtual hip markers
if(settings.add_foot_virtual_markers)

    % find AJC, MT5 and TOE markers
    footMarkerNames = ["RHEE", "RAJC", "LAJC", "RMT5", "LHEE", "LMT5", "RTOE", "LTOE"];
    NfootMarkers = length(footMarkerNames);
    [~,colIdx] = ismember(footMarkerNames, markerLabelsFiltered); colIdx = colIdx(colIdx>0);

    if(length(colIdx) ~= NfootMarkers)
        warning(['Not all required foot markers were found. Check naming and joint centres! Found markers are: ' char(strjoin(markerLabelsFiltered(colIdx),", "))])
    else
        % extract AJC, MT5 and TOE marker data
        Ndata = length(markerStructLowpass.time);
        footMarkerData = zeros(Ndata,3,NfootMarkers);
        for markerIdx = 1:NfootMarkers
            footMarkerData(:,:,markerIdx) = markerStructLowpass.(footMarkerNames(markerIdx));
        end

        % compute virtual markers
        [virtualMarkerLabels, virtualMarkerData] = computeFootVirtualMarkers(footMarkerNames, footMarkerData);

        % add markers to table
        NvirtualMarkers = length(virtualMarkerLabels);
        for markerIdx = 1:NvirtualMarkers
            markerStructLowpass.(virtualMarkerLabels(markerIdx)) = virtualMarkerData(:,:,markerIdx);
        end
        markerLabelsFiltered = string(fieldnames(markerStructLowpass));
    end
end

%% Add Table Meta Data
markerTableProcessed = osimTableFromStruct(markerStructLowpass);
for keyIdx = 1:length(markerMetaDataKeys)
    markerTableProcessed.addTableMetaDataString(markerMetaDataKeys(keyIdx),markerMetaDataValues(keyIdx));
end

%% Replace Marker Labels
% assign new labels
if isfield(settings, "marker_dictionary")
    newLabels = markerLabelsFiltered(markerLabelsFiltered~="time");         % original labels (except time)
    dicKeys = settings.marker_dictionary.keys;
    dicVals = settings.marker_dictionary.values;
    [locLabels, locDict] = ismember(newLabels, dicKeys);                    % location of labels in column labels & dictionary
    newLabels(locLabels) = dicVals(locDict(locDict>0));                     % new labels from dictionary
    newColumnLabels = StdVectorString();                                    % create OpenSim StdVector
    for labelIdx = 1:length(newLabels)                                      % fill with new labels
        newColumnLabels.add(newLabels(labelIdx));
    end
    markerTableProcessed.setColumnLabels(newColumnLabels);                  % assign updated labels
end

%% Save Filtered Marker Data
trcAdapter = TRCFileAdapter();
trcAdapter.write(markerTableProcessed, trc_file);
disp(['Processed marker data written to: ' char(trc_file)]);

end
