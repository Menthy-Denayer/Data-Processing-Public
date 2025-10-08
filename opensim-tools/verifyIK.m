clear all
clc
close all

%% Choose IK Directory
ikDIR = uigetdir("", "Choose IK results directory");

%% Choose Gait Events
% Load gait event file (file containing heel strike events for both legs)
[mat_file_name, mat_file_loc] = uigetfile(".mat","Choose .mat file to process");
gaitEvents = load(fullfile(mat_file_loc,mat_file_name));

%% Find IK Marker Errors
dirInfo = struct2table(dir(ikDIR));
[~,~,fileExtensions] = fileparts(dirInfo.name);
stoFiles = string(dirInfo.name(contains(dirInfo.name,"_ik_marker_errors.sto")));
NIKfiles = length(stoFiles); 

%% Split Data 
[Normal, Weighted1kg, Weighted2kg, Weighted3kg, Weighted4kg, Weighted5kg] = splitData(stoFiles);

%% Plot Errors
readPlot(gaitEvents.events, Normal, ikDIR, ["marker_error_RMS" "marker_error_max"], "SUBJ01_", "_markers_ik_marker_errors.sto")
% readPlot(gaitEvents.events, Weighted1kg, ikDIR, ["marker_error_RMS" "marker_error_max"], "SUBJ01_", "_markers_ik_marker_errors.sto")
% readPlot(gaitEvents.events, Weighted2kg, ikDIR, ["marker_error_RMS" "marker_error_max"], "SUBJ01_", "_markers_ik_marker_errors.sto")
% readPlot(gaitEvents.events, Weighted3kg, ikDIR, ["marker_error_RMS" "marker_error_max"], "SUBJ01_", "_markers_ik_marker_errors.sto")
% readPlot(gaitEvents.events, Weighted4kg, ikDIR, ["marker_error_RMS" "marker_error_max"], "SUBJ01_", "_markers_ik_marker_errors.sto")
% readPlot(gaitEvents.events, Weighted5kg, ikDIR, ["marker_error_RMS" "marker_error_max"], "SUBJ01_", "_markers_ik_marker_errors.sto")

%% Helper Function
% Function to split the file names into categories for easier comparison
function [Normal, Weighted1kg, Weighted2kg, Weighted3kg, Weighted4kg, Weighted5kg] = splitData(fileNames)
    Normal = fileNames(contains(fileNames,"normal","IgnoreCase",true));
    Weighted1kg = fileNames(contains(fileNames,"1kg"));
    Weighted2kg = fileNames(contains(fileNames,"2kg"));
    Weighted3kg = fileNames(contains(fileNames,"3kg"));
    Weighted4kg = fileNames(contains(fileNames,"4kg"));
    Weighted5kg = fileNames(contains(fileNames,"5kg"));
end

% Function to read and plot the data
function readPlot(events, fileNames, fileDir, colheaders, prefix, suffix)
    
    Nfiles = length(fileNames);
    Ncol = length(colheaders);
    legendEntries = strrep(strrep(strrep(fileNames,suffix,""),prefix,""),"_"," ");

    figList = [];
    for colIdx = 1:Ncol
        figList = [figList figure(colIdx)]; hold on;
        t = tiledlayout(figList(colIdx), ceil(sqrt(Nfiles)), ceil(sqrt(Nfiles)));  
        title(t, strrep(colheaders(colIdx),"_"," "))
    end
    
    for fileIdx = 1:Nfiles
        data = importdata(fullfile(fileDir, fileNames(fileIdx)));
        isCol = ismember(data.colheaders, colheaders);
        time = data.data(:,1);
        plotData = data.data(:,isCol);
        
        LHEEstrike = events.(strrep(fileNames(fileIdx),suffix,"")).LHeelStrike;
        RHEEstrike = events.(strrep(fileNames(fileIdx),suffix,"")).RHeelStrike;

        startTime = min(LHEEstrike(1), RHEEstrike(1));
        endTime = max(LHEEstrike(2), RHEEstrike(2));
        
        for colIdx = 1:Ncol

             % define limits
            if(contains(colheaders(colIdx),"RMS"))
                minErr = 0.02;
                medErr = 0.025;
                maxErr = 0.03;
            elseif(contains(colheaders(colIdx),"max"))
                minErr = 0.04;
                medErr = 0.045;
                maxErr = 0.05;
            end

            MinErrTooLargeData = plotData(:,colIdx); 
            MinErrTooLargeData(MinErrTooLargeData <= minErr) = NaN;

            MedErrTooLargeData = plotData(:,colIdx); 
            MedErrTooLargeData(MedErrTooLargeData <= medErr) = NaN;

            MaxErrTooLargeData = plotData(:,colIdx); 
            MaxErrTooLargeData(MaxErrTooLargeData <= maxErr) = NaN;

            figure(figList(colIdx))
            nexttile(fileIdx)
            hold on
            plot(time, plotData(:,colIdx),"Color","black")
            plot(time, MinErrTooLargeData, "Color", "yellow")
            plot(time, MedErrTooLargeData, "Color", [1 0.5 0])
            plot(time, MaxErrTooLargeData, "Color", "red")
            xline(startTime,"b--")
            xline(endTime,"b--")
            axis tight
            title(legendEntries(fileIdx))
        end
    end

end