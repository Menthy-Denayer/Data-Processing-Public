clear all
clc
close all

%% Add Path
% general data processing
addpath("data-processing\utilities") 

%% Define Variables
desGRFColumns = ["time", "ground_force_r_vx", "ground_force_r_vy", "ground_force_r_vz", "ground_force_r_px", "ground_force_r_py", "ground_force_r_pz", "ground_moment_r_mx", "ground_moment_r_my", "ground_moment_r_mz", "ground_force_l_vx", "ground_force_l_vy", "ground_force_l_vz", "ground_force_l_px", "ground_force_l_py", "ground_force_l_pz", "ground_moment_l_mx", "ground_moment_l_my", "ground_moment_l_mz"];
desEMGColumns = ["Biceps Femoris" "Semitendinosus" "Rectus Femoris" "Vastus Lateralis" "Vastus Medialis" "Gastrocnemius Medialis" "Gastrocnemius Lateralis" "Soleus"];
desEMGColumns = ["time", desEMGColumns + " Right", desEMGColumns + " Left"];
desEMGColumns = replace(desEMGColumns," ", "_");

% define time 
resampTime = 0:0.01:1;
Ndata = length(resampTime);

% save figures
exportFigure = false;

%% Load Events File
% File containing heel strike events for both legs
[mat_file_name, mat_file_loc] = uigetfile(".mat","Choose .mat file to process");
gaitEvents = load(fullfile(mat_file_loc,mat_file_name));

% Check empty events
expNames = string(fieldnames(gaitEvents.events));
for i = 1:length(expNames)
    if(isempty(gaitEvents.events.(expNames(i)).LHeelStrike))
        fprintf(['Empty gait events for: ' char(expNames(i)) '\n'])
    end
end

%% Load MOT Kinematics Data
% results of IK
ikDir = uigetdir("","Choose directory with kinematics .mot files to process");
dirInfo = struct2table(dir(ikDir));
[~,~,kinFileExtensions] = fileparts(dirInfo.name);
ikFiles = string(dirInfo.name(ismember(kinFileExtensions, ".mot")));
NkinFiles = length(ikFiles); 
SUBJID = split(ikFiles(1),"_"); SUBJID = double(strrep(SUBJID(1),"SUBJ",""));

%% Load STO EMG Data
% EMG
emgDir = uigetdir("","Choose directory with emg .sto files to process");
dirInfo = struct2table(dir(emgDir));
[~,~,emgFileExtensions] = fileparts(dirInfo.name);
emgFiles = string(dirInfo.name(ismember(emgFileExtensions, ".sto")));
NemgFiles = length(emgFiles); 

%% Load STO GRF Data
% GRF
grfDir = uigetdir("","Choose directory with grf .mot files to process");
dirInfo = struct2table(dir(grfDir));
[~,~,grfFileExtensions] = fileparts(dirInfo.name);
grfFiles = string(dirInfo.name(ismember(grfFileExtensions, ".mot")));
NgrfFiles = length(grfFiles); 

%% Load STO ID Data
% ID
idDir = uigetdir("","Choose directory with ID .sto files to process");
dirInfo = struct2table(dir(idDir));
[~,~,idFileExtensions] = fileparts(dirInfo.name);
idFiles = string(dirInfo.name(ismember(idFileExtensions, ".sto")));
NidFiles = length(idFiles); 

%% Load STO Power Data
% Joint Power
powerDir = uigetdir("","Choose directory with joint power .sto files to process");
dirInfo = struct2table(dir(powerDir));
powerFiles = string(dirInfo.name(contains(dirInfo.name, "power.sto")));
NpowerFiles = length(powerFiles); 

%% Load STO Body Kinematics Data
BKDir = uigetdir("","Choose directory with body kinematics .sto files to process");
dirInfo = struct2table(dir(BKDir));
BKFiles = string(dirInfo.name(contains(dirInfo.name, "BodyKinematics_pos_global.sto")));
NBKFiles = length(BKFiles); 

%% Find Kinematics Labels
% import first kinematics file to find IK labels
IKstruct = importdata(fullfile(ikDir,ikFiles(1)));
desKINColumns = string(IKstruct.colheaders);
NkinCol = length(desKINColumns);
isRightKIN = endsWith(desKINColumns(2:end),"_r"); 
isLeftKIN = endsWith(desKINColumns(2:end),"_l");

%% Define GRF Settings
NgrfCol = length(desGRFColumns);
isRightGRF = contains(desGRFColumns(2:end),"_r_"); 
isLeftGRF = contains(desGRFColumns(2:end),"_l_");

%% Define EMG Settings
NemgCol = length(desEMGColumns);
isRightEMG = contains(desEMGColumns(2:end),"Right"); 
isLeftEMG = contains(desEMGColumns(2:end),"Left");

%% Find ID Labels
% import first ID file to find ID labels
IDstruct = importdata(fullfile(idDir,idFiles(1)));
desIDColumns = string(IDstruct.colheaders);
NidCol = length(desIDColumns);
isRightID = contains(desIDColumns(2:end),"_r_"); 
isLeftID = contains(desIDColumns(2:end),"_l_");
isOtherID = ~isLeftID & ~isRightID;

% some data, without a side, is dependent on L/R heel strike, 
% i.e. sign switches around
oppositeSignLabels = ["pelvis_tx_force", "pelvis_tilt_moment",...
    "pelvis_rotation_moment", "lumbar_bending_moment", "lumbar_rotation_moment"];
isSignOpposite = ismember(desIDColumns(2:end),oppositeSignLabels);

%% Find Power Labels
% import first power file to find joint power labels
POWstruct = importdata(fullfile(powerDir,powerFiles(1)));
desPOWColumns = string(POWstruct.colheaders);
NpowCol = length(desPOWColumns);
isRightPOW = contains(desPOWColumns(2:end),"_r_"); 
isLeftPOW = contains(desPOWColumns(2:end),"_l_");
isOtherPOW = ~isLeftPOW & ~isRightPOW;

%% Align MOT Kinematics Data
% 0->100% of gait cycle
IKdataTot = NaN(Ndata, NkinCol-1, NkinFiles);                               % time data excluded
EMGdataTot = NaN(Ndata, NemgCol-1, NemgFiles);                              % time data excluded
GRFdataTot = NaN(Ndata, NgrfCol-1, NgrfFiles);                              % time data excluded, first 3 right, next 3 left
IDdataTot = NaN(Ndata, NidCol-1, NkinFiles);                                % time data excluded
POWdataTot = NaN(Ndata, NpowCol-1, NpowerFiles);                            % time data excluded 
avgSpeed = NaN(NkinFiles,1);

f = waitbar(0, 'Processing data...');
for fileIdx = 1:NkinFiles
    expName = split(ikFiles(fileIdx),"_markers_ik.mot"); 
    expName = expName(1);
    RHeelStrike = gaitEvents.events.(expName).RHeelStrike;
    LHeelStrike = gaitEvents.events.(expName).LHeelStrike;
    
    waitbar(fileIdx/NkinFiles, f, ['Processing file: ' num2str(fileIdx) '/' num2str(NkinFiles)])

    if(~isempty(RHeelStrike))

        if(RHeelStrike(1) < LHeelStrike(1))                                 % last heel strikes are on the left side
            FGHeelStrike = LHeelStrike;
            switchData = false;
        else                                                                % last heel strikes are on the right side
            FGHeelStrike = RHeelStrike;             
            switchData = true;
        end

        % IK results
        try
            fprintf(['Processing kinematics file: ' char(replace(ikFiles(fileIdx),"_"," ")) ' (' num2str(fileIdx) '/' num2str(NkinFiles) ')\n'])
            [IKdata, avgSpeed(fileIdx)] = processData(fullfile(ikDir,ikFiles(fileIdx)), desKINColumns, LHeelStrike, RHeelStrike, resampTime, "_l",[]);
            IKdataTot(:,:,fileIdx) = IKdata;
        catch
            fprintf('No IK files found to process.\n')
        end
        
        % EMG data
        try
            fprintf(['Processing emg file: ' char(replace(emgFiles(fileIdx),"_"," ")) ' (' num2str(fileIdx) '/' num2str(NemgFiles) ')\n'])
            [EMGdata,~] = processData(fullfile(emgDir,emgFiles(fileIdx)), desEMGColumns, LHeelStrike, RHeelStrike, resampTime, "_Left",[]);
            EMGdataTot(:,:,fileIdx) = EMGdata;
        catch ME
            fprintf('No EMG files found to process.\n')
        end

        % GRF data
        try 
            fprintf(['Processing grf file: ' char(replace(grfFiles(fileIdx),"_"," ")) ' (' num2str(fileIdx) '/' num2str(NgrfFiles) ')\n'])
            [GRFdata,~] = processData(fullfile(grfDir,grfFiles(fileIdx)), desGRFColumns, LHeelStrike, RHeelStrike, resampTime, "_l_",fullfile(BKDir, BKFiles(fileIdx)));
            GRFdataTot(:,:,fileIdx) = GRFdata;
        catch ME
            fprintf('No GRF files found to process.\n')
            warning(ME.identifier,'%s',ME.message)
        end

        % ID results
        try 
            fprintf(['Processing id file: ' char(replace(idFiles(fileIdx),"_"," ")) ' (' num2str(fileIdx) '/' num2str(NidFiles) ')\n'])
            [IDdata,~] = processData(fullfile(idDir,idFiles(fileIdx)), desIDColumns, FGHeelStrike, FGHeelStrike, resampTime, "_l_",[]);
            
            % change left/right sides
            if(switchData)
                IDdataTot(:,isRightID,fileIdx) = IDdata(:,isLeftID);
                IDdataTot(:,isLeftID,fileIdx) = IDdata(:,isRightID);
                IDdataTot(:,isOtherID,fileIdx) = IDdata(:,isOtherID);
                IDdataTot(:,isSignOpposite,fileIdx) = IDdataTot(:,isSignOpposite,fileIdx)*-1;
            else
                IDdataTot(:,:,fileIdx) = IDdata;
            end
        catch
            fprintf('No ID files found to process.\n')
        end

        % Power results
        try 
            fprintf(['Processing power file: ' char(replace(powerFiles(fileIdx),"_"," ")) ' (' num2str(fileIdx) '/' num2str(NpowerFiles) ')\n'])
            [POWdata,~] = processData(fullfile(powerDir,powerFiles(fileIdx)), desPOWColumns, FGHeelStrike, FGHeelStrike, resampTime, "_l_",[]);
            
            % change left/right sides
            if(switchData)
                POWdataTot(:,isRightPOW,fileIdx) = POWdata(:,isLeftPOW);
                POWdataTot(:,isLeftPOW,fileIdx) = POWdata(:,isRightPOW);
                POWdataTot(:,isOtherPOW,fileIdx) = POWdata(:,isOtherPOW);
            else
                POWdataTot(:,:,fileIdx) = POWdata;
            end

        catch
            fprintf('No power files found to process.\n')
        end
    end
end
close(f)

%% Remove EMG Zeroes
for fileIdx = 1:NemgFiles
    for colIdx = 1:NemgCol-1
        if(all(EMGdataTot(:,colIdx,fileIdx)==0))
            EMGdataTot(:,colIdx,fileIdx) = NaN;
        end
    end
end

%% Split Data in Normal & Weighted Walking
% find normal/weighted indices
normalWalkingIdx = contains(ikFiles,"Normal");
weightedWalking1kgIdx = contains(ikFiles,"1kg");
weightedWalking2kgIdx = contains(ikFiles,"2kg");
weightedWalking3kgIdx = contains(ikFiles,"3kg");
weightedWalking4kgIdx = contains(ikFiles,"4kg");
weightedWalking5kgIdx = contains(ikFiles,"5kg");

% split kinematics data into seperate arrays
IKdataTotNormal = IKdataTot(:,:,normalWalkingIdx);
IKdataTotWeighted1kg = IKdataTot(:,:,weightedWalking1kgIdx);
IKdataTotWeighted2kg = IKdataTot(:,:,weightedWalking2kgIdx);
IKdataTotWeighted3kg = IKdataTot(:,:,weightedWalking3kgIdx);
IKdataTotWeighted4kg = IKdataTot(:,:,weightedWalking4kgIdx);
IKdataTotWeighted5kg = IKdataTot(:,:,weightedWalking5kgIdx);

% split emg data into seperate arrays
EMGdataTotNormal = EMGdataTot(:,:,normalWalkingIdx);
EMGdataTotWeighted1kg = EMGdataTot(:,:,weightedWalking1kgIdx);
EMGdataTotWeighted2kg = EMGdataTot(:,:,weightedWalking2kgIdx);
EMGdataTotWeighted3kg = EMGdataTot(:,:,weightedWalking3kgIdx);
EMGdataTotWeighted4kg = EMGdataTot(:,:,weightedWalking4kgIdx);
EMGdataTotWeighted5kg = EMGdataTot(:,:,weightedWalking5kgIdx);

% split grf data into seperate arrays
GRFdataTotNormal = GRFdataTot(:,:,normalWalkingIdx);
GRFdataTotWeighted1kg = GRFdataTot(:,:,weightedWalking1kgIdx);
GRFdataTotWeighted2kg = GRFdataTot(:,:,weightedWalking2kgIdx);
GRFdataTotWeighted3kg = GRFdataTot(:,:,weightedWalking3kgIdx);
GRFdataTotWeighted4kg = GRFdataTot(:,:,weightedWalking4kgIdx);
GRFdataTotWeighted5kg = GRFdataTot(:,:,weightedWalking5kgIdx);

% split ID data into seperate arrays
IDdataTotNormal = IDdataTot(:,:,normalWalkingIdx);
IDdataTotWeighted1kg = IDdataTot(:,:,weightedWalking1kgIdx);
IDdataTotWeighted2kg = IDdataTot(:,:,weightedWalking2kgIdx);
IDdataTotWeighted3kg = IDdataTot(:,:,weightedWalking3kgIdx);
IDdataTotWeighted4kg = IDdataTot(:,:,weightedWalking4kgIdx);
IDdataTotWeighted5kg = IDdataTot(:,:,weightedWalking5kgIdx);

% split ID data into seperate arrays
POWdataTotNormal = POWdataTot(:,:,normalWalkingIdx);
POWdataTotWeighted1kg = POWdataTot(:,:,weightedWalking1kgIdx);
POWdataTotWeighted2kg = POWdataTot(:,:,weightedWalking2kgIdx);
POWdataTotWeighted3kg = POWdataTot(:,:,weightedWalking3kgIdx);
POWdataTotWeighted4kg = POWdataTot(:,:,weightedWalking4kgIdx);
POWdataTotWeighted5kg = POWdataTot(:,:,weightedWalking5kgIdx);

% split speed data into seperate arrays
avgSpeedNormal = avgSpeed(normalWalkingIdx);
avgSpeedWeighted1kg = avgSpeed(weightedWalking1kgIdx);
avgSpeedWeighted2kg = avgSpeed(weightedWalking2kgIdx);
avgSpeedWeighted3kg = avgSpeed(weightedWalking3kgIdx);
avgSpeedWeighted4kg = avgSpeed(weightedWalking4kgIdx);
avgSpeedWeighted5kg = avgSpeed(weightedWalking5kgIdx);

%% Compute Mean & STD
% mean & std kinematics 
meanKinNormalWalking = mean(IKdataTotNormal,3,"omitnan");
meanKinWeightedWalking1kg = mean(IKdataTotWeighted1kg,3,"omitnan");
meanKinWeightedWalking2kg = mean(IKdataTotWeighted2kg,3,"omitnan");
meanKinWeightedWalking3kg = mean(IKdataTotWeighted3kg,3,"omitnan");
meanKinWeightedWalking4kg = mean(IKdataTotWeighted4kg,3,"omitnan");
meanKinWeightedWalking5kg = mean(IKdataTotWeighted5kg,3,"omitnan");

stdKinNormalWalking = std(IKdataTotNormal,0,3,"omitnan");
stdKinWeightedWalking1kg = std(IKdataTotWeighted1kg,0,3,"omitnan");
stdKinWeightedWalking2kg = std(IKdataTotWeighted2kg,0,3,"omitnan");
stdKinWeightedWalking3kg = std(IKdataTotWeighted3kg,0,3,"omitnan");
stdKinWeightedWalking4kg = std(IKdataTotWeighted4kg,0,3,"omitnan");
stdKinWeightedWalking5kg = std(IKdataTotWeighted5kg,0,3,"omitnan");

% mean & std emg 
meanEMGNormalWalking = mean(EMGdataTotNormal,3,"omitnan");
meanEMGWeightedWalking1kg = mean(EMGdataTotWeighted1kg,3,"omitnan");
meanEMGWeightedWalking2kg = mean(EMGdataTotWeighted2kg,3,"omitnan");
meanEMGWeightedWalking3kg = mean(EMGdataTotWeighted3kg,3,"omitnan");
meanEMGWeightedWalking4kg = mean(EMGdataTotWeighted4kg,3,"omitnan");
meanEMGWeightedWalking5kg = mean(EMGdataTotWeighted5kg,3,"omitnan");

stdEMGNormalWalking = std(EMGdataTotNormal,0,3,"omitnan");
stdEMGWeightedWalking1kg = std(EMGdataTotWeighted1kg,0,3,"omitnan");
stdEMGWeightedWalking2kg = std(EMGdataTotWeighted2kg,0,3,"omitnan");
stdEMGWeightedWalking3kg = std(EMGdataTotWeighted3kg,0,3,"omitnan");
stdEMGWeightedWalking4kg = std(EMGdataTotWeighted4kg,0,3,"omitnan");
stdEMGWeightedWalking5kg = std(EMGdataTotWeighted5kg,0,3,"omitnan");

% mean & std grf 
meanGRFNormalWalking = mean(GRFdataTotNormal,3,"omitnan");
meanGRFWeightedWalking1kg = mean(GRFdataTotWeighted1kg,3,"omitnan");
meanGRFWeightedWalking2kg = mean(GRFdataTotWeighted2kg,3,"omitnan");
meanGRFWeightedWalking3kg = mean(GRFdataTotWeighted3kg,3,"omitnan");
meanGRFWeightedWalking4kg = mean(GRFdataTotWeighted4kg,3,"omitnan");
meanGRFWeightedWalking5kg = mean(GRFdataTotWeighted5kg,3,"omitnan");

stdGRFNormalWalking = std(GRFdataTotNormal,0,3,"omitnan");
stdGRFWeightedWalking1kg = std(GRFdataTotWeighted1kg,0,3,"omitnan");
stdGRFWeightedWalking2kg = std(GRFdataTotWeighted2kg,0,3,"omitnan");
stdGRFWeightedWalking3kg = std(GRFdataTotWeighted3kg,0,3,"omitnan");
stdGRFWeightedWalking4kg = std(GRFdataTotWeighted4kg,0,3,"omitnan");
stdGRFWeightedWalking5kg = std(GRFdataTotWeighted5kg,0,3,"omitnan");

% mean & std id 
meanIDNormalWalking = mean(IDdataTotNormal,3,"omitnan");
meanIDWeightedWalking1kg = mean(IDdataTotWeighted1kg,3,"omitnan");
meanIDWeightedWalking2kg = mean(IDdataTotWeighted2kg,3,"omitnan");
meanIDWeightedWalking3kg = mean(IDdataTotWeighted3kg,3,"omitnan");
meanIDWeightedWalking4kg = mean(IDdataTotWeighted4kg,3,"omitnan");
meanIDWeightedWalking5kg = mean(IDdataTotWeighted5kg,3,"omitnan");

stdIDNormalWalking = std(IDdataTotNormal,0,3,"omitnan");
stdIDWeightedWalking1kg = std(IDdataTotWeighted1kg,0,3,"omitnan");
stdIDWeightedWalking2kg = std(IDdataTotWeighted2kg,0,3,"omitnan");
stdIDWeightedWalking3kg = std(IDdataTotWeighted3kg,0,3,"omitnan");
stdIDWeightedWalking4kg = std(IDdataTotWeighted4kg,0,3,"omitnan");
stdIDWeightedWalking5kg = std(IDdataTotWeighted5kg,0,3,"omitnan");

% mean & std power 
meanPOWNormalWalking = mean(POWdataTotNormal,3,"omitnan");
meanPOWWeightedWalking1kg = mean(POWdataTotWeighted1kg,3,"omitnan");
meanPOWWeightedWalking2kg = mean(POWdataTotWeighted2kg,3,"omitnan");
meanPOWWeightedWalking3kg = mean(POWdataTotWeighted3kg,3,"omitnan");
meanPOWWeightedWalking4kg = mean(POWdataTotWeighted4kg,3,"omitnan");
meanPOWWeightedWalking5kg = mean(POWdataTotWeighted5kg,3,"omitnan");

stdPOWNormalWalking = std(POWdataTotNormal,0,3,"omitnan");
stdPOWWeightedWalking1kg = std(POWdataTotWeighted1kg,0,3,"omitnan");
stdPOWWeightedWalking2kg = std(POWdataTotWeighted2kg,0,3,"omitnan");
stdPOWWeightedWalking3kg = std(POWdataTotWeighted3kg,0,3,"omitnan");
stdPOWWeightedWalking4kg = std(POWdataTotWeighted4kg,0,3,"omitnan");
stdPOWWeightedWalking5kg = std(POWdataTotWeighted5kg,0,3,"omitnan");

% mean & std speed
meanSpeedNormalWalking = mean(avgSpeedNormal,1,"omitnan");
meanSpeedWeightedWalking1kg = mean(avgSpeedWeighted1kg,1,"omitnan");
meanSpeedWeightedWalking2kg = mean(avgSpeedWeighted2kg,1,"omitnan");
meanSpeedWeightedWalking3kg = mean(avgSpeedWeighted3kg,1,"omitnan");
meanSpeedWeightedWalking4kg = mean(avgSpeedWeighted4kg,1,"omitnan");
meanSpeedWeightedWalking5kg = mean(avgSpeedWeighted5kg,1,"omitnan");

stdSpeedNormalWalking = std(avgSpeedNormal,0,1,"omitnan");
stdSpeedWeightedWalking1kg = std(avgSpeedWeighted1kg,0,1,"omitnan");
stdSpeedWeightedWalking2kg = std(avgSpeedWeighted2kg,0,1,"omitnan");
stdSpeedWeightedWalking3kg = std(avgSpeedWeighted3kg,0,1,"omitnan");
stdSpeedWeightedWalking4kg = std(avgSpeedWeighted4kg,0,1,"omitnan");
stdSpeedWeightedWalking5kg = std(avgSpeedWeighted5kg,0,1,"omitnan");

%% Save Special Points
isKneeLeft = desKINColumns == "knee_angle_l"; isKneeLeft = isKneeLeft(2:end);
isKneeRight = desKINColumns == "knee_angle_r"; isKneeRight = isKneeRight(2:end);

KneeLeftIdx = find(isKneeLeft);
KneeRightIdx = find(isKneeRight);

[maxKneeFlexionRightNormalWalking,maxKneeFlexionRightNormalWalkingIdx] = max(meanKinNormalWalking(:,isKneeRight));
[maxKneeFlexionLeftNormalWalking,maxKneeFlexionLeftNormalWalkingIdx] = max(meanKinNormalWalking(:,isKneeLeft));
[maxKneeFlexionRightWeightedWalking1kg,maxKneeFlexionRightWeightedWalking1kgIdx] = max(meanKinWeightedWalking1kg(:,isKneeRight));
[maxKneeFlexionLeftWeightedWalking1kg,maxKneeFlexionLeftWeightedWalking1kgIdx] = max(meanKinWeightedWalking1kg(:,isKneeLeft));
[maxKneeFlexionRightWeightedWalking2kg,maxKneeFlexionRightWeightedWalking2kgIdx] = max(meanKinWeightedWalking2kg(:,isKneeRight));
[maxKneeFlexionLeftWeightedWalking2kg,maxKneeFlexionLeftWeightedWalking2kgIdx] = max(meanKinWeightedWalking2kg(:,isKneeLeft));
[maxKneeFlexionRightWeightedWalking3kg,maxKneeFlexionRightWeightedWalking3kgIdx] = max(meanKinWeightedWalking3kg(:,isKneeRight));
[maxKneeFlexionLeftWeightedWalking3kg,maxKneeFlexionLeftWeightedWalking3kgIdx] = max(meanKinWeightedWalking3kg(:,isKneeLeft));
[maxKneeFlexionRightWeightedWalking4kg,maxKneeFlexionRightWeightedWalking4kgIdx] = max(meanKinWeightedWalking4kg(:,isKneeRight));
[maxKneeFlexionLeftWeightedWalking4kg,maxKneeFlexionLeftWeightedWalking4kgIdx] = max(meanKinWeightedWalking4kg(:,isKneeLeft));
[maxKneeFlexionRightWeightedWalking5kg,maxKneeFlexionRightWeightedWalking5kgIdx] = max(meanKinWeightedWalking5kg(:,isKneeRight));
[maxKneeFlexionLeftWeightedWalking5kg,maxKneeFlexionLeftWeightedWalking5kgIdx] = max(meanKinWeightedWalking5kg(:,isKneeLeft));

%% Create Figure
% Figure properties
colors = [repmat("blue",1,5) repmat("red",1,5)];
expName = split(ikFiles,"_markers_ik.mot"); 
expName = expName(:,1);
fileType = "png";

%% Kinematics Plot
threshold = 5;      
minFrames = 5;
isDiffKin = abs(meanKinNormalWalking - meanKinWeightedWalking5kg) > threshold;
eventDiffKin = isDiffKin(2:end,:) - isDiffKin(1:end-1,:);

% time series figure
for i = 1:NkinCol                                                   
    fig = figure;
    hold on
    grid on
    plot_mean_std(resampTime, meanKinNormalWalking(:,i), stdKinNormalWalking(:,i), "blue")
    plot_mean_std(resampTime, meanKinWeightedWalking1kg(:,i), stdKinWeightedWalking1kg(:,i), [0,0,0])
    plot_mean_std(resampTime, meanKinWeightedWalking2kg(:,i), stdKinWeightedWalking2kg(:,i), [0.25,0,0])
    plot_mean_std(resampTime, meanKinWeightedWalking3kg(:,i), stdKinWeightedWalking3kg(:,i), [0.50,0,0])
    plot_mean_std(resampTime, meanKinWeightedWalking4kg(:,i), stdKinWeightedWalking3kg(:,i), [0.75,0,0])
    plot_mean_std(resampTime, meanKinWeightedWalking5kg(:,i), stdKinWeightedWalking5kg(:,i), [1,0,0])

    if(i == KneeRightIdx)
        start_norm = coordinatesToFigureLoc(ax, [0.35, maxKneeFlexionRightNormalWalking]);
        end_norm = coordinatesToFigureLoc(ax, [0.35, maxKneeFlexionRightWeightedWalking5kg]);
        annotation('arrow', [start_norm(1) end_norm(1)], [start_norm(2) end_norm(2)]);
        dp = maxKneeFlexionRightNormalWalking - maxKneeFlexionRightWeightedWalking5kg;
        text(0.42, maxKneeFlexionRightNormalWalking-dp/2,0, "-" + round(dp,2) + "°", "HorizontalAlignment", "center", "VerticalAlignment","middle")
    elseif(i == KneeLeftIdx)
        start_norm = coordinatesToFigureLoc(ax, [0.6, maxKneeFlexionLeftNormalWalking]);
        end_norm = coordinatesToFigureLoc(ax, [0.6, maxKneeFlexionLeftWeightedWalking5kg]);
        annotation('arrow', [start_norm(1) end_norm(1)], [start_norm(2) end_norm(2)]);
        dp = maxKneeFlexionLeftNormalWalking - maxKneeFlexionLeftWeightedWalking5kg;
        text(0.55, maxKneeFlexionLeftNormalWalking-dp/2, 0, "-" + round(dp,2) + "°", "HorizontalAlignment", "center", "VerticalAlignment","middle")
    end

    xlabel("Gait Cycle [%]")
    ylabel("Joint Angle [°]")
    legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
    title(replace(desKINColumns(i+1),"_"," "))
    hold off

    figname = "SUBJ" + SUBJID + "_" + desKINColumns(i+1) + "." + fileType;
    if(exportFigure)
        exportgraphics(fig,figname,"ContentType","vector","Resolution",300,"BackgroundColor","none")
    end
end

%% Kinematics Max. Knee Flexion Plot

Ntrials = size(IKdataTotNormal,3);

subfig = figure;

subplot(2,3,1)
hold on 
grid on
title("Normal Walking")
for i = 1:size(IKdataTotNormal,3)
    plot(i, max(IKdataTotNormal(:,isKneeLeft,i)),"Color","blue","MarkerFaceColor","blue","Marker","o")
end
yline(mean(max(IKdataTotNormal(:,isKneeLeft,:))),"LineWidth",1,"Color","black")
ylim([40 80])
hold off

subplot(2,3,2)
hold on 
grid on
title("Weighted Walking 1kg")
for i = 1:size(IKdataTotWeighted1kg,3)
    plot(i, max(IKdataTotWeighted1kg(:,isKneeLeft,i)),"Color",[0,0,0],"MarkerFaceColor",[0,0,0],"Marker","o")
end
yline(mean(max(IKdataTotWeighted1kg(:,isKneeLeft,:))),"LineWidth",1,"Color","black")
ylim([40 80])
hold off

subplot(2,3,3)
hold on 
grid on
title("Weighted Walking 2kg")
for i = 1:size(IKdataTotWeighted2kg,3)
    plot(i, max(IKdataTotWeighted2kg(:,isKneeLeft,i)),"Color",[0.25,0,0],"MarkerFaceColor",[0.25,0,0],"Marker","o")
end
yline(mean(max(IKdataTotWeighted2kg(:,isKneeLeft,:))),"LineWidth",1,"Color","black")
ylim([40 80])
hold off

subplot(2,3,4)
hold on 
grid on
title("Weighted Walking 3kg")
for i = 1:size(IKdataTotWeighted3kg,3)
    plot(i, max(IKdataTotWeighted3kg(:,isKneeLeft,i)),"Color",[0.50,0,0],"MarkerFaceColor",[0.50,0,0],"Marker","o")
end
yline(mean(max(IKdataTotWeighted3kg(:,isKneeLeft,:))),"LineWidth",1,"Color","black")
ylim([40 80])
hold off

subplot(2,3,5)
hold on 
grid on
title("Weighted Walking 4kg")
for i = 1:size(IKdataTotWeighted4kg,3)
    plot(i, max(IKdataTotWeighted4kg(:,isKneeLeft,i)),"Color",[0.75,0,0],"MarkerFaceColor",[0.75,0,0],"Marker","o")
end
yline(mean(max(IKdataTotWeighted4kg(:,isKneeLeft,:))),"LineWidth",1,"Color","black")
ylim([40 80])
hold off

subplot(2,3,6)
hold on 
grid on
title("Weighted Walking 5kg")
for i = 1:size(IKdataTotWeighted5kg,3)
    plot(i, max(IKdataTotWeighted5kg(:,isKneeLeft,i)),"Color",[1,0,0],"MarkerFaceColor",[1,0,0],"Marker","o")
end
yline(mean(max(IKdataTotWeighted5kg(:,isKneeLeft,:))),"LineWidth",1,"Color","black")
ylim([40 80])
hold off

% Give common xlabel, ylabel and title to your figure
han=axes(subfig,'visible','off'); 
han.Title.Visible='on';
han.XLabel.Visible='on';
han.YLabel.Visible='on';
ylabel(han,'Flexion Angle [°]');
xlabel(han,'Trial Number');
sgtitle("Maximum Knee Flexion Angle Across Trials")

%% EMG Plot
% time series figure
for i = 1:NemgCol-1                                                         % no time
    fig = figure;
    hold on
    grid on
    plot_mean_std(resampTime, meanEMGNormalWalking(:,i), stdEMGNormalWalking(:,i), "blue")
    plot_mean_std(resampTime, meanEMGWeightedWalking1kg(:,i), stdEMGWeightedWalking1kg(:,i), [0,0,0])
    plot_mean_std(resampTime, meanEMGWeightedWalking2kg(:,i), stdEMGWeightedWalking2kg(:,i), [0.25,0,0])
    plot_mean_std(resampTime, meanEMGWeightedWalking3kg(:,i), stdEMGWeightedWalking3kg(:,i), [0.50,0,0])
    plot_mean_std(resampTime, meanEMGWeightedWalking4kg(:,i), stdEMGWeightedWalking4kg(:,i), [0.75,0,0])
    plot_mean_std(resampTime, meanEMGWeightedWalking5kg(:,i), stdEMGWeightedWalking5kg(:,i), [1,0,0])
    legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
    title(replace(desEMGColumns(i+1),"_"," "))
    xlabel("Gait Cycle [%]")
    ylabel("Muscle Activation [-]")
    hold off

    figname = "SUBJ" + SUBJID + "_" + desEMGColumns(i+1) + "." + fileType;
    if(exportFigure)
        exportgraphics(fig,figname,"ContentType","vector","Resolution",300,"BackgroundColor","none")
    end
end

%% GRF Plot
GRFLabels = replace(desGRFColumns,"1","r");
GRFLabels = replace(GRFLabels,"2","l");
isLeftIdx = find(contains(GRFLabels, "l"));
% time series figure
% for i = isLeftIdx-1                                                         % no time
for i = 1:NgrfCol-1
    fig = figure;
    hold on
    grid on
    plot_mean_std(resampTime, meanGRFNormalWalking(:,i), stdGRFNormalWalking(:,i), "blue")
    plot_mean_std(resampTime, meanGRFWeightedWalking1kg(:,i), stdGRFWeightedWalking1kg(:,i), [0,0,0])
    plot_mean_std(resampTime, meanGRFWeightedWalking2kg(:,i), stdGRFWeightedWalking2kg(:,i), [0.25,0,0])
    plot_mean_std(resampTime, meanGRFWeightedWalking3kg(:,i), stdGRFWeightedWalking3kg(:,i), [0.50,0,0])
    plot_mean_std(resampTime, meanGRFWeightedWalking4kg(:,i), stdGRFWeightedWalking4kg(:,i), [0.75,0,0])
    plot_mean_std(resampTime, meanGRFWeightedWalking5kg(:,i), stdGRFWeightedWalking5kg(:,i), [1,0,0])
    legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
    % legend()
    title(replace(GRFLabels(i+1),"_"," "))
    xlabel("Gait Cycle [%]")
    ylabel("Force [N]")
    hold off

    figname = "SUBJ" + SUBJID + "_" + GRFLabels(i+1) + "." + fileType;
    if(exportFigure)
        exportgraphics(fig,figname,"ContentType","vector","Resolution",300,"BackgroundColor","none")
    end
end

%% ID Plot
% time series figure
for i = 1:NidCol-1                                                          % no time
    fig = figure;
    hold on
    grid on
    plot_mean_std(resampTime, meanIDNormalWalking(:,i), stdIDNormalWalking(:,i), "blue")
    plot_mean_std(resampTime, meanIDWeightedWalking1kg(:,i), stdIDWeightedWalking1kg(:,i), [0,0,0])
    plot_mean_std(resampTime, meanIDWeightedWalking2kg(:,i), stdIDWeightedWalking2kg(:,i), [0.25,0,0])
    plot_mean_std(resampTime, meanIDWeightedWalking3kg(:,i), stdIDWeightedWalking3kg(:,i), [0.50,0,0])
    plot_mean_std(resampTime, meanIDWeightedWalking4kg(:,i), stdIDWeightedWalking4kg(:,i), [0.75,0,0])
    plot_mean_std(resampTime, meanIDWeightedWalking5kg(:,i), stdIDWeightedWalking5kg(:,i), [1,0,0])
    legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
    title(replace(desIDColumns(i+1),"_"," "))
    xlabel("Gait Cycle [%]")
    ylabel("Moment [Nm]")
    hold off

    figname = "SUBJ" + SUBJID + "_" + desIDColumns(i+1) + "." + fileType;
    if(exportFigure)
        exportgraphics(fig,figname,"ContentType","vector","Resolution",300,"BackgroundColor","none")
    end
end

%% Power Plot
% time series figure
for i = 1:NpowCol-1                                                          % no time
    fig = figure;
    hold on
    grid on
    plot_mean_std(resampTime, meanPOWNormalWalking(:,i), stdPOWNormalWalking(:,i), "blue")
    plot_mean_std(resampTime, meanPOWWeightedWalking1kg(:,i), stdPOWWeightedWalking1kg(:,i), [0,0,0])
    plot_mean_std(resampTime, meanPOWWeightedWalking2kg(:,i), stdPOWWeightedWalking2kg(:,i), [0.25,0,0])
    plot_mean_std(resampTime, meanPOWWeightedWalking3kg(:,i), stdPOWWeightedWalking3kg(:,i), [0.50,0,0])
    plot_mean_std(resampTime, meanPOWWeightedWalking4kg(:,i), stdPOWWeightedWalking4kg(:,i), [0.75,0,0])
    plot_mean_std(resampTime, meanPOWWeightedWalking5kg(:,i), stdPOWWeightedWalking5kg(:,i), [1,0,0])
    legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
    title(replace(desPOWColumns(i+1),"_"," "))
    xlabel("Gait Cycle [%]")
    ylabel("Power [W]")
    hold off

    figname = "SUBJ" + SUBJID + "_" + desPOWColumns(i+1) + "." + fileType;
    if(exportFigure)
        exportgraphics(fig,figname,"ContentType","vector","Resolution",300,"BackgroundColor","none")
    end
end

%% Speed Plot
% bar plot
fig = figure;
hold on
grid on
bar(1, meanSpeedNormalWalking,"grouped", "blue")
bar(2, meanSpeedWeightedWalking1kg,"grouped", "red")
bar(3, meanSpeedWeightedWalking2kg,"grouped", "red")
bar(4, meanSpeedWeightedWalking3kg,"grouped", "red")
bar(5, meanSpeedWeightedWalking4kg,"grouped", "red")
bar(6, meanSpeedWeightedWalking5kg,"grouped", "red")
errorbar([meanSpeedNormalWalking meanSpeedWeightedWalking1kg meanSpeedWeightedWalking2kg meanSpeedWeightedWalking3kg meanSpeedWeightedWalking4kg meanSpeedWeightedWalking5kg], ...
    [stdSpeedNormalWalking stdSpeedWeightedWalking1kg stdSpeedWeightedWalking2kg stdSpeedWeightedWalking3kg stdSpeedWeightedWalking4kg stdSpeedWeightedWalking5kg], '.', "vertical", "Color", "black")
xticks(1:6)
xticklabels(["Normal", "Weighted 1kg", "Weighted 2kg", "Weighted 3kg", "Weighted 4kg", "Weighted 5kg"])
title("Average Walking Speed")
hold("off")
if(exportFigure)
    exportgraphics(fig,"SUBJ" + SUBJID + "_avgSpeed"+ "." + fileType,"ContentType","vector","Resolution",300,"BackgroundColor","none")
end

%% Save Data
% save headers
data.headers.kinematics = desKINColumns(2:end);
data.headers.EMG = desEMGColumns(2:end);
data.headers.kinetics = desIDColumns(2:end);
data.headers.GRF = desGRFColumns(2:end);
data.headers.power = desPOWColumns(2:end);

% save kinematics
data.("SUBJ" + SUBJID).kinematics.IkdataNormal = IKdataTotNormal;
data.("SUBJ" + SUBJID).kinematics.IkdataWeighted1kg = IKdataTotWeighted1kg;
data.("SUBJ" + SUBJID).kinematics.IkdataWeighted2kg = IKdataTotWeighted2kg;
data.("SUBJ" + SUBJID).kinematics.IkdataWeighted3kg = IKdataTotWeighted3kg;
data.("SUBJ" + SUBJID).kinematics.IkdataWeighted4kg = IKdataTotWeighted4kg;
data.("SUBJ" + SUBJID).kinematics.IkdataWeighted5kg = IKdataTotWeighted5kg;

% save EMG
data.("SUBJ" + SUBJID).EMG.EMGdataNormal = EMGdataTotNormal;
data.("SUBJ" + SUBJID).EMG.EMGdataWeighted1kg = EMGdataTotWeighted1kg;
data.("SUBJ" + SUBJID).EMG.EMGdataWeighted2kg = EMGdataTotWeighted2kg;
data.("SUBJ" + SUBJID).EMG.EMGdataWeighted3kg = EMGdataTotWeighted3kg;
data.("SUBJ" + SUBJID).EMG.EMGdataWeighted4kg = EMGdataTotWeighted4kg;
data.("SUBJ" + SUBJID).EMG.EMGdataWeighted5kg = EMGdataTotWeighted5kg;

% save GRF
data.("SUBJ" + SUBJID).GRF.GRFdataNormal = GRFdataTotNormal;
data.("SUBJ" + SUBJID).GRF.GRFdataWeighted1kg = GRFdataTotWeighted1kg;
data.("SUBJ" + SUBJID).GRF.GRFdataWeighted2kg = GRFdataTotWeighted2kg;
data.("SUBJ" + SUBJID).GRF.GRFdataWeighted3kg = GRFdataTotWeighted3kg;
data.("SUBJ" + SUBJID).GRF.GRFdataWeighted4kg = GRFdataTotWeighted4kg;
data.("SUBJ" + SUBJID).GRF.GRFdataWeighted5kg = GRFdataTotWeighted5kg;

% save ID
data.("SUBJ" + SUBJID).kinetics.IDdataNormal = IDdataTotNormal;
data.("SUBJ" + SUBJID).kinetics.IDdataWeighted1kg = IDdataTotWeighted1kg;
data.("SUBJ" + SUBJID).kinetics.IDdataWeighted2kg = IDdataTotWeighted2kg;
data.("SUBJ" + SUBJID).kinetics.IDdataWeighted3kg = IDdataTotWeighted3kg;
data.("SUBJ" + SUBJID).kinetics.IDdataWeighted4kg = IDdataTotWeighted4kg;
data.("SUBJ" + SUBJID).kinetics.IDdataWeighted5kg = IDdataTotWeighted5kg;

% save Power
data.("SUBJ" + SUBJID).power.POWdataNormal = POWdataTotNormal;
data.("SUBJ" + SUBJID).power.POWdataWeighted1kg = POWdataTotWeighted1kg;
data.("SUBJ" + SUBJID).power.POWdataWeighted2kg = POWdataTotWeighted2kg;
data.("SUBJ" + SUBJID).power.POWdataWeighted3kg = POWdataTotWeighted3kg;
data.("SUBJ" + SUBJID).power.POWdataWeighted4kg = POWdataTotWeighted4kg;
data.("SUBJ" + SUBJID).power.POWdataWeighted5kg = POWdataTotWeighted5kg;

% save speed
data.("SUBJ" + SUBJID).speed.speedNormal = avgSpeedNormal;
data.("SUBJ" + SUBJID).speed.speedWeighted1kg = avgSpeedWeighted1kg;
data.("SUBJ" + SUBJID).speed.speedWeighted2kg = avgSpeedWeighted2kg;
data.("SUBJ" + SUBJID).speed.speedWeighted3kg = avgSpeedWeighted3kg;
data.("SUBJ" + SUBJID).speed.speedWeighted4kg = avgSpeedWeighted4kg;
data.("SUBJ" + SUBJID).speed.speedWeighted5kg = avgSpeedWeighted5kg;

save("MAT_normalizedData-vNew.mat","data")

%% Functions
% plot mean data with a 1-std gray band
function plot_mean_std(time, mean, std, color)

    % Compute 68 % interval bounds
    lower_bound = mean - std;
    upper_bound = mean + std;
    time_shaded = [time fliplr(time)];
    
    shaded = [lower_bound' fliplr(upper_bound')];                           % Deviation shaded area y-values
    fill(time_shaded,shaded,"black","FaceAlpha",0.1,'EdgeColor','none')     % Fill shaded area between mean +/- sigma
    plot(time, mean,"LineWidth",1,"Color",color)

end

% find the nearest index of timePoint inside timeVector
function idx = findTimeIdx(timeVector, timePoint)
    [dist,idx] = min(abs(timeVector-timePoint));
    if(dist > 0.5)
        warning(['Time distance is larger than 0.5 (' num2str(dist) ')!'])
        idx = 1;
    end
end

% process the data (resampling)
function [procData,avgSpeed] = processData(fileName, desCol, LHeelStrike, RHeelStrike, resampTime, delim, BKfile)
    % import data
    Datastruct = importdata(fileName);
    Rawdata = Datastruct.data;
    Datacolumns = Datastruct.colheaders;
    [~,colIdx] = ismember(desCol, Datacolumns); colIdx = colIdx(colIdx>0);
    Rawdata = Rawdata(:,colIdx);
    Time = Rawdata(:,1);

    % split left/right
    isLeft = contains(desCol,delim,"IgnoreCase",true) & ~contains(desCol,"pelvis","IgnoreCase",true);
    isRight = ~isLeft; isRight(1) = 0;                                       % ignore time

    % create empty matrix to store processed data
    Ncol = size(Rawdata,2);
    Nrow = length(resampTime);
    procData = NaN(Nrow, Ncol);

    % find heel strike times
    startTimeR = RHeelStrike(1);
    endTimeR = RHeelStrike(2);
    startTimeL = LHeelStrike(1);
    endTimeL = LHeelStrike(2);

    % find indices
    startIdxR = findTimeIdx(Time, startTimeR);
    endIdxR = findTimeIdx(Time, endTimeR);
    startIdxL = findTimeIdx(Time, startTimeL);
    endIdxL = findTimeIdx(Time, endTimeL);

    if(any(contains(desCol,"pelvis_tz")))
        tzIdx = find(desCol=="pelvis_tz");

        % compute average speed
        deltaT = endTimeR - startTimeR;
        deltaX = Rawdata(startIdxR,tzIdx) - Rawdata(endIdxR, tzIdx);
        avgSpeed = deltaX/deltaT;
        tzIdx = tzIdx + 1;
    else
        avgSpeed = [];
        tzIdx = 0;
    end

    % resample data
    procData(:,isRight) = averageGaitCycle(Time, Rawdata(:,isRight), [startIdxR, endIdxR], resampTime, tzIdx, false);
    procData(:,isLeft) = averageGaitCycle(Time, Rawdata(:,isLeft), [startIdxL, endIdxL], resampTime, tzIdx, false);

    % correct COPz
    if(~isempty(BKfile))
        % import BK data
        calcnCol = ["time" "calcn_r_X", "calcn_r_Z", "calcn_l_X", "calcn_l_Z"];
        BKstruct = importdata(BKfile);
        BKdata = BKstruct.data;
        Datacolumns = BKstruct.colheaders;
        [~,colIdx] = ismember(calcnCol, Datacolumns); colIdx = colIdx(colIdx>0);
        BKdata = BKdata(:,colIdx);
        BKTime = BKdata(:,1);
    
        % find heel strike times
        startTimeR = RHeelStrike(1);
        endTimeR = RHeelStrike(2);
        startTimeL = LHeelStrike(1);
        endTimeL = LHeelStrike(2);
    
        % find indices
        startIdxR = findTimeIdx(BKTime, startTimeR);
        endIdxR = findTimeIdx(BKTime, endTimeR);
        startIdxL = findTimeIdx(BKTime, startTimeL);
        endIdxL = findTimeIdx(BKTime, endTimeL);
    
        % resample body kinematics data
        procBKdata = NaN(length(resampTime), length(calcnCol)-1);
        isRight = contains(calcnCol,"_r_");
        isLeft = contains(calcnCol,"_l_");
        procBKdata(:,isRight) = averageGaitCycle(BKTime, BKdata(:,isRight), [startIdxR, endIdxR], resampTime, 0, false);
        procBKdata(:,isLeft) = averageGaitCycle(BKTime, BKdata(:,isLeft), [startIdxL, endIdxL], resampTime, 0, false);

        % normalize COP
        isCOPR = contains(desCol,"_r_px") | contains(desCol,"_r_pz");
        isCOPL = contains(desCol,"_l_px") | contains(desCol,"_l_pz");
        procData(:,isCOPR) = normalizeCOP(procData(:,isCOPR), procBKdata(:,isRight));
        procData(:,isCOPL) = normalizeCOP(procData(:,isCOPL), procBKdata(:,isLeft));
    end

    procData = procData(:,2:end);

end

% normalizes COP progression of the foot to the calcn origin
function normCOP = normalizeCOP(data, BKdata)
    % normalize COP
    isNotZero = abs(data) > 0;
    Ncol = size(data,2);
    normCOP = data;

    for colIdx = 1:Ncol
        COPnotZero = data(isNotZero(:,colIdx),colIdx);
        BKnotZero = BKdata(isNotZero(:,colIdx),colIdx);
        normCOP(isNotZero(:,colIdx),colIdx) = (COPnotZero-BKnotZero);
    end

    normCOP(:,2) = normCOP(:,2) * -1;
end