clear all
clc
close all

%% ----------------------------- Description ------------------------------
% This code allows to save the IK errors to verify that they are
% within the bounds defined by OpenSim.

% The user needs to select the following data directories and files:
%   o gait events structure (.mat)
%   o directory with IK results (.mot)
%   o IK error structure (.mat)

%% -----------------------------------------------------------------------

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
headers = ["total_squared_error" "marker_error_RMS" "marker_error_max"];

meanIKerrNormal = getIKerr(gaitEvents.events, Normal, ikDIR, headers, "_markers_ik_marker_errors.sto");
meanIKerrWeighted1kg = getIKerr(gaitEvents.events, Weighted1kg, ikDIR, headers, "_markers_ik_marker_errors.sto");
meanIKerrWeighted2kg = getIKerr(gaitEvents.events, Weighted2kg, ikDIR, headers, "_markers_ik_marker_errors.sto");
meanIKerrWeighted3kg = getIKerr(gaitEvents.events, Weighted3kg, ikDIR, headers, "_markers_ik_marker_errors.sto");
meanIKerrWeighted4kg = getIKerr(gaitEvents.events, Weighted4kg, ikDIR, headers, "_markers_ik_marker_errors.sto");
meanIKerrWeighted5kg = getIKerr(gaitEvents.events, Weighted5kg, ikDIR, headers, "_markers_ik_marker_errors.sto");

%% Save IK Errors
[IKerrFile, IKerrDir] = uigetfile(".mat", "Choose existing IK error structure.");

load(fullfile(IKerrDir, IKerrFile));

SUBJID = strsplit(ikDIR,"analysis\"); SUBJID = extractBefore(SUBJID{2},"\IK"); SUBJID = double(strrep(SUBJID,"SUBJ",""));
IKerr.("SUBJ" + SUBJID).meanIKerrNormal = meanIKerrNormal;
IKerr.("SUBJ" + SUBJID).meanIKerrWeighted1kg = meanIKerrWeighted1kg;
IKerr.("SUBJ" + SUBJID).meanIKerrWeighted2kg = meanIKerrWeighted2kg;
IKerr.("SUBJ" + SUBJID).meanIKerrWeighted3kg = meanIKerrWeighted3kg;
IKerr.("SUBJ" + SUBJID).meanIKerrWeighted4kg = meanIKerrWeighted4kg;
IKerr.("SUBJ" + SUBJID).meanIKerrWeighted5kg = meanIKerrWeighted5kg;
IKerr.headers = headers;

%% Save Scaling Errors
IKerr.SUBJ1.SCALEerr = [NaN, 0.015, 0.020];
IKerr.SUBJ2.SCALEerr = [NaN, 0.017, 0.021];
IKerr.SUBJ4.SCALEerr = [NaN, 0.016, 0.022];
IKerr.SUBJ5.SCALEerr = [NaN, 0.012, 0.018];
IKerr.SUBJ6.SCALEerr = [NaN, 0.014, 0.020];
IKerr.SUBJ7.SCALEerr = [NaN, 0.015, 0.022];
IKerr.SUBJ8.SCALEerr = [NaN, 0.015, 0.023];
IKerr.SUBJ9.SCALEerr = [NaN, 0.014, 0.021];
IKerr.SUBJ10.SCALEerr = [NaN, 0.015, 0.021];
IKerr.SUBJ11.SCALEerr = [NaN, 0.015, 0.019];
IKerr.SUBJ12.SCALEerr = [NaN, 0.014, 0.019];
IKerr.SUBJ13.SCALEerr = [NaN, 0.014, 0.019];
IKerr.SUBJ14.SCALEerr = [NaN, 0.017, 0.024];

save(fullfile(IKerrDir, IKerrFile),"IKerr")

%% Print Errors
% matrixheadersRMS = repmat("RMS ",1,7) + ["0 kg", "1 kg", "2 kg", "3 kg", "4 kg", "5 kg", "scale"]; 
% matrixheadersMAX = repmat("MAX ",1,7) + ["0 kg", "1 kg", "2 kg", "3 kg", "4 kg", "5 kg", "scale"]; 
matrixheaders = ["0 kg", "1 kg", "2 kg", "3 kg", "4 kg", "5 kg", "scale"]; 

print_struct_latex(IKerr, "SUBJ", headers(2), matrixheaders, '%.2f')
print_struct_latex(IKerr, "SUBJ", headers(3), matrixheaders, '%.2f')

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

% find index of time point closest to desired value
function idx = findTimeIdx(timeVector, timePoint)
[dist,idx] = min(abs(timeVector-timePoint));
if(dist > 0.5)
    warning(['Time distance is larger than 0.5 (' num2str(dist) ')!'])
    idx = 1;
end
end

% Function to read and plot the data
function meanErr = getIKerr(events, fileNames, fileDir, colheaders, suffix)
    
    Nfiles = length(fileNames);
    meanErr = NaN(Nfiles, length(colheaders));
    
    for fileIdx = 1:Nfiles
        data = importdata(fullfile(fileDir, fileNames(fileIdx)));
        isCol = ismember(data.colheaders, colheaders);
        time = data.data(:,1);
        rawData = data.data(:,isCol);
        
        LHEEstrike = events.(strrep(fileNames(fileIdx),suffix,"")).LHeelStrike;
        RHEEstrike = events.(strrep(fileNames(fileIdx),suffix,"")).RHeelStrike;

        startTime = min(LHEEstrike(1), RHEEstrike(1));
        endTime = max(LHEEstrike(2), RHEEstrike(2));
        
        startIdx = findTimeIdx(time, startTime);
        endIdx = findTimeIdx(time, endTime);

        meanErr(fileIdx,:) = mean(rawData(startIdx:endIdx,:),1);
        
    end

end

% Prints the data in the command window in Latex table format
function print_struct_latex(struct, includeFields, colheaders, matrixheaders, notation)

% Define Variables
fieldNames = string(fieldnames(struct));
fieldNames = fieldNames(contains(fieldNames, includeFields));
Nfields = length(fieldNames);
isHeader = contains(struct.headers, colheaders);
Nheaders = length(isHeader(isHeader > 0));
subfieldNames = string(fieldnames(struct.(fieldNames(1))));
Nsubfields = length(subfieldNames);

% Generate Matrix
Ncases = Nheaders * Nsubfields;
MeanMatrix = zeros(Nfields, Ncases);
StdMatrix = zeros(Nfields, Ncases);
for i = 1:Nfields
    for j = 1:Nsubfields
        errors = struct.(fieldNames(i)).(subfieldNames(j));
        MeanMatrix(i,j) = mean(errors(:,isHeader),1);
        StdMatrix(i,j) = std(errors(:,isHeader),[],1);
    end
end

% Print Matrix
print_matrix_latex(round(MeanMatrix,2), round(StdMatrix,2), matrixheaders, strrep(fieldNames,"_"," "), notation)
end

% Prints the data in the command window in Latex table format
function print_matrix_latex(matrix, std_matrix, colheaders, rownames, notation)

Nrow = size(matrix,1);
Ncol = size(matrix,2);

if(isempty(notation))
    notation = '%.2f';
end

% print data
for i = 1:Nrow+1
    for j = 1:Ncol+1
        if(j < Ncol+1)
            token = '& ';
        elseif(i == 1 && j == Ncol + 1)
            token = '\\\\ \\hline';
        else
            token = '\\\\';
        end

        if(i == 1 && j == 1)
            fprintf(token)
        elseif(i == 1 && j > 1)
            fprintf('\\textbf{' + string(colheaders(j-1)) + '} ' + token)
        elseif(i > 1 && j == 1)
            fprintf('\\textbf{' + string(rownames(i-1)) + '} ' + token)
        elseif(matrix(i-1,j-1) == i && ~isempty(std_matrix))
            fprintf(['\\textbf{' notation '$\\pm$ ' notation '} ' token], matrix(i-1,j-1), std_matrix(i-1,j-1))
        elseif(matrix(i-1,j-1) == i)
            fprintf(['\\textbf{' notation '} ' token], matrix(i-1,j-1))
        elseif(~isempty(std_matrix))
            fprintf([notation '$\\pm$ ' notation ' ' token], matrix(i-1,j-1), std_matrix(i-1,j-1))
        else
            fprintf([notation ' ' token], matrix(i-1,j-1))
        end
    end
    fprintf('\n')
end

end