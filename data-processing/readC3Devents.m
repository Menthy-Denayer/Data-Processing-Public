function events = readC3Devents(settings)

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
    footOffSides = eventSides(isFootOff);
    
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