function events = readC3Devents(settings)
%% readC3Devents - Reads heel strike events stored inside the C3D file
% - only the last 2 heel strikes are saved, as these are on the force plates
%
%------------------------------------------- INPUTS -------------------------------------------
% settings                              | struct                | Configuration structure with fields:
%   settings.c3d_path_file              | string                | Full path to the input .c3d file
%
%------------------------------------------ OUTPUTS -------------------------------------------
% events                                | struct                | Structure containing the heel strikes for each trial
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% ezc3d toolbox                         | https://github.com/pyomeca/ezc3d
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 09/Oct/2025

% Last Update: Menthy Denayer
% Date: 09/Oct/2025 : Added description

%% Load C3D File
c3d = ezc3dRead(settings.c3d_path_file);

%% Read C3D Info
startFrame = c3d.header.points.firstFrame;
frameRate = c3d.header.points.frameRate;
startTime = startFrame/frameRate;

%% Read Events Data
if(~isfield(c3d.parameters,"EVENT"))
    events.RHeelStrike = [];
    events.LHeelStrike = [];
    return
end

if isfield(c3d.parameters.EVENT,"LABELS")
    eventTypes = c3d.parameters.EVENT.LABELS.DATA;
    eventTimes = c3d.parameters.EVENT.TIMES.DATA(2,:)-startTime;
    eventSides = c3d.parameters.EVENT.CONTEXTS.DATA;
    
    isRightStrike = contains(eventTypes,"Strike") & contains(eventSides,"Right");
    isLeftStrike = contains(eventTypes,"Strike") & contains(eventSides,"Left");
    isFootOff = contains(eventTypes,"Foot Off");
    % footOffSides = eventSides(isFootOff);
    
    RheelStrike = sort(eventTimes(isRightStrike));
    LheelStrike = sort(eventTimes(isLeftStrike));
    
    [finalFootOff, ~] = max(eventTimes(isFootOff));
    % finalFootOffSide = footOffSides(indexFootOff);
    
    RheelStrike = RheelStrike(RheelStrike < finalFootOff);
    RheelStrike = RheelStrike(end-1:end);
    LheelStrike = LheelStrike(LheelStrike < finalFootOff);
    LheelStrike = LheelStrike(end-1:end);
    
    events.RHeelStrike = RheelStrike;
    events.LHeelStrike = LheelStrike;
else
    events.RHeelStrike = [];
    events.LHeelStrike = [];
end
end