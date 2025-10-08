clear all
clc
close all

%% ----------------------------- Description ------------------------------
% This code allows to visualize the processed data, stored inside the 
% summary MAT file (MAT_normalizedData-vOct2025.mat). 

% The user can choose the subject ID and data to plot. 

%% ---------------------------- User Settings -----------------------------
% Choose Subject
subjID = 1;

% Choose Plot
plotIK = false;
plotID = false;
plotGRF = false;
plotEMG = false;
plotPOW = false;
plotSpeed = false;

% Export figures
exportFigure = false;
fileType = "png";

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
IKheaders = data.headers.kinematics;

isPelvisPos = contains(IKheaders,"_tx") | contains(IKheaders,"_ty") | contains(IKheaders,"_tz");  
IKylabels = repmat("Joint Angle [°]", length(IKheaders),1);
IKylabels(isPelvisPos) = "Position [m]";

% emg data
EMGdataNormal = subjDATA.EMG.EMGdataNormal;
EMGdataWeight1kg = subjDATA.EMG.EMGdataWeighted1kg;
EMGdataWeight2kg = subjDATA.EMG.EMGdataWeighted2kg;
EMGdataWeight3kg = subjDATA.EMG.EMGdataWeighted3kg;
EMGdataWeight4kg = subjDATA.EMG.EMGdataWeighted4kg;
EMGdataWeight5kg = subjDATA.EMG.EMGdataWeighted5kg;
EMGheaders = data.headers.EMG;

EMGylabels = repmat("Muscle Activation [-]", length(EMGheaders),1);

% grf data
GRFdataNormal = subjDATA.GRF.GRFdataNormal;
GRFdataWeight1kg = subjDATA.GRF.GRFdataWeighted1kg;
GRFdataWeight2kg = subjDATA.GRF.GRFdataWeighted2kg;
GRFdataWeight3kg = subjDATA.GRF.GRFdataWeighted3kg;
GRFdataWeight4kg = subjDATA.GRF.GRFdataWeighted4kg;
GRFdataWeight5kg = subjDATA.GRF.GRFdataWeighted5kg;
GRFheaders = data.headers.GRF;

isMoment = contains(GRFheaders,"_moment_");
isPoint = contains(GRFheaders,"_p");
GRFylabels = repmat("Force [N]",length(GRFheaders),1);
GRFylabels(isMoment) = "Moment [Nm]";
GRFylabels(isPoint) = "Position [m]";

% id data
IDdataNormal = subjDATA.kinetics.IDdataNormal;
IDdataWeight1kg = subjDATA.kinetics.IDdataWeighted1kg;
IDdataWeight2kg = subjDATA.kinetics.IDdataWeighted2kg;
IDdataWeight3kg = subjDATA.kinetics.IDdataWeighted3kg;
IDdataWeight4kg = subjDATA.kinetics.IDdataWeighted4kg;
IDdataWeight5kg = subjDATA.kinetics.IDdataWeighted5kg;
IDheaders = data.headers.kinetics;

isForce = contains(IDheaders,"_force");
IDylabels = repmat("Joint Moment [Nm]",length(IDheaders),1);
IDylabels(isForce) = "Joint Force [N]";

% power data
POWdataNormal = subjDATA.power.POWdataNormal;
POWdataWeight1kg = subjDATA.power.POWdataWeighted1kg;
POWdataWeight2kg = subjDATA.power.POWdataWeighted2kg;
POWdataWeight3kg = subjDATA.power.POWdataWeighted3kg;
POWdataWeight4kg = subjDATA.power.POWdataWeighted4kg;
POWdataWeight5kg = subjDATA.power.POWdataWeighted5kg;
POWheaders = data.headers.power;

POWylabels = repmat("Joint Power [W]", length(POWheaders),1);

% speed data
avgSpeedNormal = subjDATA.speed.speedNormal;
avgSpeedWeight1kg= subjDATA.speed.speedWeighted1kg;
avgSpeedWeight2kg = subjDATA.speed.speedWeighted2kg;
avgSpeedWeight3kg = subjDATA.speed.speedWeighted3kg;
avgSpeedWeight4kg = subjDATA.speed.speedWeighted4kg;
avgSpeedWeight5kg = subjDATA.speed.speedWeighted5kg;

%% Define Variables
resampTime = 0:0.01:1;

%% Plot Kinematics
if(plotIK)
    plotSUBJ(resampTime, IKdataNormal, IKdataWeight1kg, IKdataWeight2kg, IKdataWeight3kg, IKdataWeight4kg, IKdataWeight5kg, "Gait [%]", "Joint Angle [°]", IKheaders, exportFigure)
    plotAllSubjects(resampTime, data, "kinematics", data.headers.kinematics, "Gait Cycle [%]", IKylabels, true)
end

%% Plot GRF
if(plotGRF)
    plotSUBJ(resampTime, GRFdataNormal, GRFdataWeight1kg, GRFdataWeight2kg, GRFdataWeight3kg, GRFdataWeight4kg, GRFdataWeight5kg, "Gait [%]", "Force [N]", GRFheaders, exportFigure)
    plotAllSubjects(resampTime, data, "GRF", data.headers.GRF, "Gait Cycle [%]", GRFylabels, true)
end

%% Plot Kinetics
if(plotID)
    plotSUBJ(resampTime, IDdataNormal, IDdataWeight1kg, IDdataWeight2kg, IDdataWeight3kg, IDdataWeight4kg, IDdataWeight5kg, "Gait [%]", "Joint Moment [Nm]", IDheaders, exportFigure)
    plotAllSubjects(resampTime, data, "kinetics", data.headers.kinetics, "Gait Cycle [%]", IDylabels, true)
end

%% Plot Powers
if(plotPOW)
    plotSUBJ(resampTime, POWdataNormal, POWdataWeight1kg, POWdataWeight2kg, POWdataWeight3kg, POWdataWeight4kg, POWdataWeight5kg, "Gait [%]", "Joint Power [W]", POWheaders, exportFigure)
    plotAllSubjects(resampTime, data, "power", data.headers.power, "Gait Cycle [%]", POWylabels, true)
end

%% Plot EMG
if(plotEMG)
    plotSUBJ(resampTime, EMGdataNormal, EMGdataWeight1kg, EMGdataWeight2kg, EMGdataWeight3kg, EMGdataWeight4kg, EMGdataWeight5kg, "Gait [%]", "Muscle Activations [-]", EMGheaders, exportFigure)
    plotAllSubjects(resampTime, data, "EMG", data.headers.EMG, "Gait Cycle [%]", EMGylabels, true)
end

%% Compute Mean
meanSpeedNormal = mean(avgSpeedNormal,1,"omitnan");
meanSpeedWeight1kg = mean(avgSpeedWeight1kg,1,"omitnan");
meanSpeedWeight2kg = mean(avgSpeedWeight2kg,1,"omitnan");
meanSpeedWeight3kg = mean(avgSpeedWeight3kg,1,"omitnan");
meanSpeedWeight4kg = mean(avgSpeedWeight4kg,1,"omitnan");
meanSpeedWeight5kg = mean(avgSpeedWeight5kg,1,"omitnan");

%% Compute STD
stdSpeedNormal = std(avgSpeedNormal,0,1,"omitnan");
stdSpeedWeight1kg = std(avgSpeedWeight1kg,0,1,"omitnan");
stdSpeedWeight2kg = std(avgSpeedWeight2kg,0,1,"omitnan");
stdSpeedWeight3kg = std(avgSpeedWeight3kg,0,1,"omitnan");
stdSpeedWeight4kg = std(avgSpeedWeight4kg,0,1,"omitnan");
stdSpeedWeight5kg = std(avgSpeedWeight5kg,0,1,"omitnan");

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

    if(exportFigure)
        exportgraphics(fig,"SUBJ" + subjID + "_avgSpeed"+ "." + fileType,"ContentType","vector","Resolution",300,"BackgroundColor","none")
    end
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

% Function to read and plot the data
function plotSUBJ(resampTime, normalData, W1kgData, W2kgData, W3kgData, W4kgData, W5kgData, xlabel_txt, ylabel_txt, varheaders, exportFigure)
    
    % compute mean
    meanNormal = mean(normalData,3,"omitnan");
    meanWeight1kg = mean(W1kgData,3,"omitnan");
    meanWeight2kg = mean(W2kgData,3,"omitnan");
    meanWeight3kg = mean(W3kgData,3,"omitnan");
    meanWeight4kg = mean(W4kgData,3,"omitnan");
    meanWeight5kg = mean(W5kgData,3,"omitnan");
    
    % compute STD
    stdnormal = std(normalData,0,3,"omitnan");
    stdweight1kg = std(W1kgData,0,3,"omitnan");
    stdweight2kg = std(W2kgData,0,3,"omitnan");
    stdweight3kg = std(W3kgData,0,3,"omitnan");
    stdweight4kg = std(W4kgData,0,3,"omitnan");
    stdweight5kg = std(W5kgData,0,3,"omitnan");

    Nvar = size(normalData,2);

    for varIdx = 1:Nvar
        fig = figure;
        grid on
        hold on
        plot_mean_std(resampTime, meanNormal(:,varIdx), stdnormal(:,varIdx), "blue")
        plot_mean_std(resampTime, meanWeight1kg(:,varIdx), stdweight1kg(:,varIdx), [0,0,0])
        plot_mean_std(resampTime, meanWeight2kg(:,varIdx), stdweight2kg(:,varIdx), [0.25,0,0])
        plot_mean_std(resampTime, meanWeight3kg(:,varIdx), stdweight3kg(:,varIdx), [0.50,0,0])
        plot_mean_std(resampTime, meanWeight4kg(:,varIdx), stdweight4kg(:,varIdx), [0.75,0,0])
        plot_mean_std(resampTime, meanWeight5kg(:,varIdx), stdweight5kg(:,varIdx), [1,0,0])
    
        ylabel(ylabel_txt)
        xlabel(xlabel_txt)
        legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'best')
        title(strrep(varheaders(varIdx),"_"," "))
        hold off

        % save figure
        if(exportFigure)
            figname = "SUBJ" + subjID + "_" + varheaders(varIdx) + "." + fileType;
            exportgraphics(fig,figname,"ContentType","vector","Resolution",300,"BackgroundColor","none")
        end
    end

end

% Function to read and plot the data
function plotAllSubjects(resampTime, ALLdata, varLabel, varHeaders, xlabel_txt, ylabel_txt, exportFigure)
    
    fieldNames = string(fieldnames(ALLdata));
    SUBJnames = fieldNames(contains(fieldNames,"SUBJ"));
    NSUBJ = length(SUBJnames);
    Nvar = length(varHeaders);
    varFields = string(fieldnames(ALLdata.(SUBJnames(1)).(varLabel)));

    figList = [];
    for varIdx = 1:Nvar
        figList = [figList figure(varIdx)]; hold on;
        t = tiledlayout(figList(varIdx), ceil(sqrt(NSUBJ)), ceil(sqrt(NSUBJ)));  
        title(t, strrep(varHeaders(varIdx),"_"," "))
        ylabel(t,ylabel_txt(varIdx))
        xlabel(t,xlabel_txt)
    end
    

    for SUBJIdx = 1:NSUBJ
        % extract data
        normalData = ALLdata.(SUBJnames(SUBJIdx)).(varLabel).(varFields(1));
        W1kgData = ALLdata.(SUBJnames(SUBJIdx)).(varLabel).(varFields(2));
        W2kgData = ALLdata.(SUBJnames(SUBJIdx)).(varLabel).(varFields(3));
        W3kgData = ALLdata.(SUBJnames(SUBJIdx)).(varLabel).(varFields(4));
        W4kgData = ALLdata.(SUBJnames(SUBJIdx)).(varLabel).(varFields(5));
        W5kgData = ALLdata.(SUBJnames(SUBJIdx)).(varLabel).(varFields(6));

        % compute mean
        meanNormal = mean(normalData,3,"omitnan");
        meanWeight1kg = mean(W1kgData,3,"omitnan");
        meanWeight2kg = mean(W2kgData,3,"omitnan");
        meanWeight3kg = mean(W3kgData,3,"omitnan");
        meanWeight4kg = mean(W4kgData,3,"omitnan");
        meanWeight5kg = mean(W5kgData,3,"omitnan");
        
        % compute STD
        stdnormal = std(normalData,0,3,"omitnan");
        stdweight1kg = std(W1kgData,0,3,"omitnan");
        stdweight2kg = std(W2kgData,0,3,"omitnan");
        stdweight3kg = std(W3kgData,0,3,"omitnan");
        stdweight4kg = std(W4kgData,0,3,"omitnan");
        stdweight5kg = std(W5kgData,0,3,"omitnan");

        % data = importdata(fullfile(fileDir, fileNames(SUBJIdx)));
        % isCol = ismember(data.colheaders, colheaders);
        % plotData = data.data(:,isCol);
        
        for varIdx = 1:Nvar
            figure(figList(varIdx))
            nexttile(SUBJIdx)
            grid on
            hold on
            plot_mean_std(resampTime, meanNormal(:,varIdx), stdnormal(:,varIdx), "blue")
            plot_mean_std(resampTime, meanWeight1kg(:,varIdx), stdweight1kg(:,varIdx), [0,0,0])
            plot_mean_std(resampTime, meanWeight2kg(:,varIdx), stdweight2kg(:,varIdx), [0.25,0,0])
            plot_mean_std(resampTime, meanWeight3kg(:,varIdx), stdweight3kg(:,varIdx), [0.50,0,0])
            plot_mean_std(resampTime, meanWeight4kg(:,varIdx), stdweight4kg(:,varIdx), [0.75,0,0])
            plot_mean_std(resampTime, meanWeight5kg(:,varIdx), stdweight5kg(:,varIdx), [1,0,0])
       
            title(strrep(varHeaders(varIdx),"_"," "))

            hold off
            axis tight
            title(SUBJnames(SUBJIdx))

            if(SUBJIdx == NSUBJ)
                lgd = legend(["" "Normal" "" "Weighted 1kg" "" "Weighted 2kg" "" "Weighted 3kg" "" "Weighted 4kg" "" "Weighted 5kg"], 'Location', 'bestoutside');
                lgd.Layout.Tile = ceil(sqrt(NSUBJ))^2;
                lgd.FontSize = 6;

                % save figure
                if(exportFigure)
                    figname = "allSUBJ_" + varHeaders(varIdx) + ".png";
                    exportgraphics(figList(varIdx),figname,"ContentType","vector","Resolution",300,"BackgroundColor","none")
                end
            end
        end

    end
end