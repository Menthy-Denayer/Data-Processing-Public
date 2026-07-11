clear all
clc
close all

%% ----------------------------- Description ------------------------------
% This code creates 5 weighted models for a desired subject, based on a
% scaled model and the measured locations of the weights.

% The user needs to select the following data directories and files:
%   o processed data structure, containing the weight locations (.mat)
%   o scaled OpenSim model (.osim)

%% ---------------------------- User Settings -----------------------------
% Choose subject
SUBJID = 4;

%% Import Libraries
import org.opensim.modeling.*;

%% Load Experimental Data
[dataFilePath, dataFileDir]= uigetfile(".mat","Choose data file");
load(fullfile(dataFileDir,dataFilePath));

%% Load OpenSim Model
[file_name, data_loc] = uigetfile("*.osim","Select .osim file.");
gaitModel = Model(data_loc+"/"+file_name);
outputDir = data_loc + "weightedModels\";

%% Check Output Directory
if(~exist(outputDir,"dir"))
    mkdir(outputDir);
end

%% Find RKNE Marker  
markers = gaitModel.getMarkerSet();
RKNEmarker = markers.get("RKNE");
localPos = RKNEmarker.get_location();

Rfemur = gaitModel.getBodySet().get('femur_r');                             % original frame of RKNE marker
RfemurFrame = Rfemur;                                                       % since Body inherits PhysicalFrame

Rtibia = gaitModel.getBodySet().get('tibia_r');                             % desired frame of RKNE marker
RtibiaFrame = Rtibia;                                                       % since Body inherits PhysicalFrame

% transform marker position from femur to tibia
state = gaitModel.initSystem();
RtibiaPos = Rfemur.findStationLocationInAnotherFrame(state, localPos, RtibiaFrame);
markerRKNEtib = [RtibiaPos.get(0), RtibiaPos.get(1), RtibiaPos.get(2)];

%% Create Weighted Model
heightList = [0.11, 0.145, 0.17, 0.175, 0.19];                              % measured, m
widthList = [0.070, 0.085, 0.10, 0.10, 0.1025];                             % measured, m
thickList = [0.01, 0.015, 0.015, 0.02, 0.02];                               % measured, m

for mass = 1:5
    % desired values
    descirc = data.("SUBJ" + SUBJID).char.weight_circ.("circ" + mass + "kg")*0.01;
    desloc = data.("SUBJ" + SUBJID).char.weight_loc.("loc" + mass + "kg")*0.01;

    % create weighted model
    [x_l,y_l,inertia_l,x_r,y_r,inertia_r] = createWeightedModel(gaitModel,mass,heightList(mass),widthList(mass),thickList(mass),descirc,desloc,markerRKNEtib, outputDir);

    % save weight info
    data.("SUBJ" + SUBJID).char.weight_pos.("pos_l_" + mass + "kg") = [x_l, y_l];
    data.("SUBJ" + SUBJID).char.weight_inertia.("inertia_l_" + mass + "kg") = inertia_l;
    data.("SUBJ" + SUBJID).char.weight_pos.("pos_r_" + mass + "kg") = [x_r, y_r];
    data.("SUBJ" + SUBJID).char.weight_inertia.("inertia_r_" + mass + "kg") = inertia_r;
    data.("SUBJ" + SUBJID).char.weight_height.("height" + mass + "kg") = heightList(mass);
    data.("SUBJ" + SUBJID).char.weight_width.("width" + mass + "kg") = 4*widthList(mass);
    data.("SUBJ" + SUBJID).char.weight_thickness.("thickness" + mass + "kg") = thickList(mass);
end

%% Save Data
% save(fullfile(dataFileDir,dataFilePath),"data")
