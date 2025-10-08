clear all
clc
close all

%% ----------------------------- Description ------------------------------
% This code allows to visualize the processed data, stored inside the 
% summary MAT file (MAT_normalizedData-vOct2025.mat). 

% The user can choose the subject ID and data to plot. 

%% ---------------------------- User Settings -----------------------------
% Choose Subject
subjID = 6;

% Choose Plot
plotIK = false;
plotID = false;
plotGRF = false;
plotEMG = false;
plotPOW = false;
plotSpeed = true;

%% ------------------------------------------------------------------------

%% Choose Data Structure
[dataFilePath, dataFileDir]= uigetfile(".mat","Choose data file");

%% Load Processed Data
load(fullfile(dataFileDir,dataFilePath));

fieldNames = string(fieldnames(data));
fieldSUBJ = fieldNames(contains(fieldNames,"SUBJ"));
NSUBJ = length(fieldSUBJ);

%% Extract Data
subjDATA = data.("SUBJ" + subjID);
% kin data
IKdataNormal = subjDATA.kinematics.IkdataNormal;
IKdataWeight1kg = subjDATA.kinematics.IkdataWeighted1kg;
IKdataWeight2kg = subjDATA.kinematics.IkdataWeighted2kg;
IKdataWeight3kg = subjDATA.kinematics.IkdataWeighted3kg;
IKdataWeight4kg = subjDATA.kinematics.IkdataWeighted4kg;
IKdataWeight5kg = subjDATA.kinematics.IkdataWeighted5kg;

% emg data
EMGdataNormal = subjDATA.EMG.EMGdataNormal;
EMGdataWeight1kg = subjDATA.EMG.EMGdataWeighted1kg;
EMGdataWeight2kg = subjDATA.EMG.EMGdataWeighted2kg;
EMGdataWeight3kg = subjDATA.EMG.EMGdataWeighted3kg;
EMGdataWeight4kg = subjDATA.EMG.EMGdataWeighted4kg;
EMGdataWeight5kg = subjDATA.EMG.EMGdataWeighted5kg;

% grf data
GRFdataNormal = subjDATA.GRF.GRFdataNormal;
GRFdataWeight1kg = subjDATA.GRF.GRFdataWeighted1kg;
GRFdataWeight2kg = subjDATA.GRF.GRFdataWeighted2kg;
GRFdataWeight3kg = subjDATA.GRF.GRFdataWeighted3kg;
GRFdataWeight4kg = subjDATA.GRF.GRFdataWeighted4kg;
GRFdataWeight5kg = subjDATA.GRF.GRFdataWeighted5kg;

% id data
IDdataNormal = subjDATA.kinetics.IDdataNormal;
IDdataWeight1kg = subjDATA.kinetics.IDdataWeighted1kg;
IDdataWeight2kg = subjDATA.kinetics.IDdataWeighted2kg;
IDdataWeight3kg = subjDATA.kinetics.IDdataWeighted3kg;
IDdataWeight4kg = subjDATA.kinetics.IDdataWeighted4kg;
IDdataWeight5kg = subjDATA.kinetics.IDdataWeighted5kg;

% power data
POWdataNormal = subjDATA.power.POWdataNormal;
POWdataWeight1kg = subjDATA.power.POWdataWeighted1kg;
POWdataWeight2kg = subjDATA.power.POWdataWeighted2kg;
POWdataWeight3kg = subjDATA.power.POWdataWeighted3kg;
POWdataWeight4kg = subjDATA.power.POWdataWeighted4kg;
POWdataWeight5kg = subjDATA.power.POWdataWeighted5kg;

% speed data
avgSpeedNormal = subjDATA.speed.speedNormal;
avgSpeedWeight1kg= subjDATA.speed.speedWeighted1kg;
avgSpeedWeight2kg = subjDATA.speed.speedWeighted2kg;
avgSpeedWeight3kg = subjDATA.speed.speedWeighted3kg;
avgSpeedWeight4kg = subjDATA.speed.speedWeighted4kg;
avgSpeedWeight5kg = subjDATA.speed.speedWeighted5kg;

%% Define Variables
Ndata = size(subjDATA.kinematics.IkdataNormal,1);
Nkin = size(subjDATA.kinematics.IkdataNormal,2);
Nemg = size(subjDATA.EMG.EMGdataNormal,2);
Ngrf = size(subjDATA.GRF.GRFdataNormal,2);
Nid = size(subjDATA.kinetics.IDdataNormal,2);
Npow = size(subjDATA.power.POWdataNormal,2);
resampTime = 0:0.01:1;

%% Compute Mean
meanIKnormal = mean(IKdataNormal,3,"omitnan");
meanIKweight1kg = mean(IKdataWeight1kg,3,"omitnan");
meanIKweight2kg = mean(IKdataWeight2kg,3,"omitnan");
meanIKweight3kg = mean(IKdataWeight3kg,3,"omitnan");
meanIKweight4kg = mean(IKdataWeight4kg,3,"omitnan");
meanIKweight5kg = mean(IKdataWeight5kg,3,"omitnan");

meanGRFnormal = mean(GRFdataNormal,3,"omitnan");
meanGRFweight1kg = mean(GRFdataWeight1kg,3,"omitnan");
meanGRFweight2kg = mean(GRFdataWeight2kg,3,"omitnan");
meanGRFweight3kg = mean(GRFdataWeight3kg,3,"omitnan");
meanGRFweight4kg = mean(GRFdataWeight4kg,3,"omitnan");
meanGRFweight5kg = mean(GRFdataWeight5kg,3,"omitnan");

meanEMGnormal = mean(EMGdataNormal,3,"omitnan");
meanEMGweight1kg = mean(EMGdataWeight1kg,3,"omitnan");
meanEMGweight2kg = mean(EMGdataWeight2kg,3,"omitnan");
meanEMGweight3kg = mean(EMGdataWeight3kg,3,"omitnan");
meanEMGweight4kg = mean(EMGdataWeight4kg,3,"omitnan");
meanEMGweight5kg = mean(EMGdataWeight5kg,3,"omitnan");

meanIDnormal = mean(IDdataNormal,3,"omitnan");
meanIDweight1kg = mean(IDdataWeight1kg,3,"omitnan");
meanIDweight2kg = mean(IDdataWeight2kg,3,"omitnan");
meanIDweight3kg = mean(IDdataWeight3kg,3,"omitnan");
meanIDweight4kg = mean(IDdataWeight4kg,3,"omitnan");
meanIDweight5kg = mean(IDdataWeight5kg,3,"omitnan");

meanPOWnormal = mean(POWdataNormal,3,"omitnan");
meanPOWweight1kg = mean(POWdataWeight1kg,3,"omitnan");
meanPOWweight2kg = mean(POWdataWeight2kg,3,"omitnan");
meanPOWweight3kg = mean(POWdataWeight3kg,3,"omitnan");
meanPOWweight4kg = mean(POWdataWeight4kg,3,"omitnan");
meanPOWweight5kg = mean(POWdataWeight5kg,3,"omitnan");

meanSpeedNormal = mean(avgSpeedNormal,1,"omitnan");
meanSpeedWeight1kg = mean(avgSpeedWeight1kg,1,"omitnan");
meanSpeedWeight2kg = mean(avgSpeedWeight2kg,1,"omitnan");
meanSpeedWeight3kg = mean(avgSpeedWeight3kg,1,"omitnan");
meanSpeedWeight4kg = mean(avgSpeedWeight4kg,1,"omitnan");
meanSpeedWeight5kg = mean(avgSpeedWeight5kg,1,"omitnan");

%% Compute STD
stdIKnormal = std(IKdataNormal,0,3,"omitnan");
stdIKweight1kg = std(IKdataWeight1kg,0,3,"omitnan");
stdIKweight2kg = std(IKdataWeight2kg,0,3,"omitnan");
stdIKweight3kg = std(IKdataWeight3kg,0,3,"omitnan");
stdIKweight4kg = std(IKdataWeight4kg,0,3,"omitnan");
stdIKweight5kg = std(IKdataWeight5kg,0,3,"omitnan");

stdGRFnormal = std(GRFdataNormal,0,3,"omitnan");
stdGRFweight1kg = std(GRFdataWeight1kg,0,3,"omitnan");
stdGRFweight2kg = std(GRFdataWeight2kg,0,3,"omitnan");
stdGRFweight3kg = std(GRFdataWeight3kg,0,3,"omitnan");
stdGRFweight4kg = std(GRFdataWeight4kg,0,3,"omitnan");
stdGRFweight5kg = std(GRFdataWeight5kg,0,3,"omitnan");

stdEMGnormal = std(EMGdataNormal,0,3,"omitnan");
stdEMGweight1kg = std(EMGdataWeight1kg,0,3,"omitnan");
stdEMGweight2kg = std(EMGdataWeight2kg,0,3,"omitnan");
stdEMGweight3kg = std(EMGdataWeight3kg,0,3,"omitnan");
stdEMGweight4kg = std(EMGdataWeight4kg,0,3,"omitnan");
stdEMGweight5kg = std(EMGdataWeight5kg,0,3,"omitnan");

stdIDnormal = std(IDdataNormal,0,3,"omitnan");
stdIDweight1kg = std(IDdataWeight1kg,0,3,"omitnan");
stdIDweight2kg = std(IDdataWeight2kg,0,3,"omitnan");
stdIDweight3kg = std(IDdataWeight3kg,0,3,"omitnan");
stdIDweight4kg = std(IDdataWeight4kg,0,3,"omitnan");
stdIDweight5kg = std(IDdataWeight5kg,0,3,"omitnan");

stdPOWnormal = std(POWdataNormal,0,3,"omitnan");
stdPOWweight1kg = std(POWdataWeight1kg,0,3,"omitnan");
stdPOWweight2kg = std(POWdataWeight2kg,0,3,"omitnan");
stdPOWweight3kg = std(POWdataWeight3kg,0,3,"omitnan");
stdPOWweight4kg = std(POWdataWeight4kg,0,3,"omitnan");
stdPOWweight5kg = std(POWdataWeight5kg,0,3,"omitnan");

stdSpeedNormal = std(avgSpeedNormal,0,1,"omitnan");
stdSpeedWeight1kg = std(avgSpeedWeight1kg,0,1,"omitnan");
stdSpeedWeight2kg = std(avgSpeedWeight2kg,0,1,"omitnan");
stdSpeedWeight3kg = std(avgSpeedWeight3kg,0,1,"omitnan");
stdSpeedWeight4kg = std(avgSpeedWeight4kg,0,1,"omitnan");
stdSpeedWeight5kg = std(avgSpeedWeight5kg,0,1,"omitnan");

%% Kinematics Plot
if(plotIK)
    % time series figure
    for varIdx = 1:Nkin 
    
        fig = figure;
        grid on
        hold on
        plot_mean_std(resampTime, meanIKnormal(:,varIdx), stdIKnormal(:,varIdx), "blue")
        plot_mean_std(resampTime, meanIKweight1kg(:,varIdx), stdIKweight1kg(:,varIdx), [0,0,0])
        plot_mean_std(resampTime, meanIKweight2kg(:,varIdx), stdIKweight2kg(:,varIdx), [0.25,0,0])
        plot_mean_std(resampTime, meanIKweight3kg(:,varIdx), stdIKweight3kg(:,varIdx), [0.50,0,0])
        plot_mean_std(resampTime, meanIKweight4kg(:,varIdx), stdIKweight4kg(:,varIdx), [0.75,0,0])
        plot_mean_std(resampTime, meanIKweight5kg(:,varIdx), stdIKweight5kg(:,varIdx), [1,0,0])
    
        ylabel("Angle [°]")
        xlabel("Time [%]")
        legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
        title(strrep(data.headers.kinematics(varIdx),"_"," "))
        hold off
    end
end

%% EMG Plot
if(plotEMG)
    for varIdx = 1:Nemg
        fig = figure;
        grid on
        hold on
        plot_mean_std(resampTime, meanEMGnormal(:,varIdx), stdEMGnormal(:,varIdx), "blue")
        plot_mean_std(resampTime, meanEMGweight1kg(:,varIdx), stdEMGweight1kg(:,varIdx), [0,0,0])
        plot_mean_std(resampTime, meanEMGweight2kg(:,varIdx), stdEMGweight2kg(:,varIdx), [0.25,0,0])
        plot_mean_std(resampTime, meanEMGweight3kg(:,varIdx), stdEMGweight3kg(:,varIdx), [0.50,0,0])
        plot_mean_std(resampTime, meanEMGweight4kg(:,varIdx), stdEMGweight4kg(:,varIdx), [0.75,0,0])
        plot_mean_std(resampTime, meanEMGweight5kg(:,varIdx), stdEMGweight5kg(:,varIdx), [1,0,0])
    
        ylabel("Muscle Activation [-]")
        xlabel("Time [%]")
        legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
        title(strrep(data.headers.EMG(varIdx),"_"," "))
        hold off
    end
end
%% GRF Plot
if(plotGRF)
    for varIdx = 1:Ngrf
        fig = figure;
        grid on
        hold on
        plot_mean_std(resampTime, meanGRFnormal(:,varIdx), stdGRFnormal(:,varIdx), "blue")
        plot_mean_std(resampTime, meanGRFweight1kg(:,varIdx), stdGRFweight1kg(:,varIdx), [0,0,0])
        plot_mean_std(resampTime, meanGRFweight2kg(:,varIdx), stdGRFweight2kg(:,varIdx), [0.25,0,0])
        plot_mean_std(resampTime, meanGRFweight3kg(:,varIdx), stdGRFweight3kg(:,varIdx), [0.50,0,0])
        plot_mean_std(resampTime, meanGRFweight4kg(:,varIdx), stdGRFweight4kg(:,varIdx), [0.75,0,0])
        plot_mean_std(resampTime, meanGRFweight5kg(:,varIdx), stdGRFweight5kg(:,varIdx), [1,0,0])
    
        ylabel("Force [N/kg]")
        xlabel("Time [%]")
        legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
        title(strrep(data.headers.GRF(varIdx),"_"," "))
        hold off
    end
end
%% ID Plot
if(plotID)
    for varIdx = 1:Nid
        fig = figure;
        grid on
        hold on
        % Ntrial = size(IDdataNormal,3);
        % for trialIdx = 1:Ntrial
        %     plot(resampTime, IDdataNormal(:,varIdx,trialIdx))
        % end
        plot_mean_std(resampTime, meanIDnormal(:,varIdx), stdIDnormal(:,varIdx), "blue")
        plot_mean_std(resampTime, meanIDweight1kg(:,varIdx), stdIDweight1kg(:,varIdx), [0,0,0])
        plot_mean_std(resampTime, meanIDweight2kg(:,varIdx), stdIDweight2kg(:,varIdx), [0.25,0,0])
        plot_mean_std(resampTime, meanIDweight3kg(:,varIdx), stdIDweight3kg(:,varIdx), [0.50,0,0])
        plot_mean_std(resampTime, meanIDweight4kg(:,varIdx), stdIDweight4kg(:,varIdx), [0.75,0,0])
        plot_mean_std(resampTime, meanIDweight5kg(:,varIdx), stdIDweight5kg(:,varIdx), [1,0,0])
    
        ylabel("Moment [Nm]")
        xlabel("Time [%]")
        legend()
        % legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
        title(strrep(data.headers.kinetics(varIdx),"_"," "))
        hold off
    end
end
%% Power Plot
if(plotPOW)
    for varIdx = 1:Npow
        fig = figure;
        grid on
        hold on
        % Ntrial = size(IDdataNormal,3);
        % for trialIdx = 1:Ntrial
        %     plot(resampTime, IDdataNormal(:,varIdx,trialIdx))
        % end
        plot_mean_std(resampTime, meanPOWnormal(:,varIdx), stdPOWnormal(:,varIdx), "blue")
        plot_mean_std(resampTime, meanPOWweight1kg(:,varIdx), stdPOWweight1kg(:,varIdx), [0,0,0])
        plot_mean_std(resampTime, meanPOWweight2kg(:,varIdx), stdPOWweight2kg(:,varIdx), [0.25,0,0])
        plot_mean_std(resampTime, meanPOWweight3kg(:,varIdx), stdPOWweight3kg(:,varIdx), [0.50,0,0])
        plot_mean_std(resampTime, meanPOWweight4kg(:,varIdx), stdPOWweight4kg(:,varIdx), [0.75,0,0])
        plot_mean_std(resampTime, meanPOWweight5kg(:,varIdx), stdPOWweight5kg(:,varIdx), [1,0,0])
    
        ylabel("Power [W]")
        xlabel("Time [%]")
        legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
        title(strrep(data.headers.power(varIdx),"_"," "))
        hold off
    end
end

%% Speed Plot
% bar plot
if(plotSpeed)
    fig = figure;
    hold on
    grid on
    bar(1, meanSpeedNormal,"grouped", "blue")
    bar(2, meanSpeedWeight1kg,"grouped", "red")
    bar(3, meanSpeedWeight2kg,"grouped", "red")
    bar(4, meanSpeedWeight3kg,"grouped", "red")
    bar(5, meanSpeedWeight4kg,"grouped", "red")
    bar(6, meanSpeedWeight5kg,"grouped", "red")
    errorbar([meanSpeedNormal meanSpeedWeight1kg meanSpeedWeight2kg meanSpeedWeight3kg meanSpeedWeight4kg meanSpeedWeight5kg], ...
        [stdSpeedNormal stdSpeedWeight1kg stdSpeedWeight2kg stdSpeedWeight3kg stdSpeedWeight4kg stdSpeedWeight5kg], '.', "vertical", "Color", "black")
    xticks(1:6)
    xticklabels(["Normal", "Weighted 1kg", "Weighted 2kg", "Weighted 3kg", "Weighted 4kg", "Weighted 5kg"])
    title("Average Walking Speed")
    hold("off")
end

%% Functions
function plot_mean_std(time, mean, std, color)

    % Compute 68 % interval bounds
    lower_bound = mean - std;
    upper_bound = mean + std;
    time_shaded = [time fliplr(time)];
    
    shaded = [lower_bound' fliplr(upper_bound')];                               % Deviation shaded area y-values
    fill(time_shaded,shaded,"black","FaceAlpha",0.1,'EdgeColor','none')         % Fill shaded area between mean +/- sigma
    plot(time, mean,"LineWidth",1,"Color",color)

end