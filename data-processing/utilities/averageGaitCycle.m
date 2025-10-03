function [average_data] = averageGaitCycle(time, data, cycleIndices, resampTime, txColumn, debug)
%% averageGaitCycle - Averages input data over 1 gait cycle
% - Takes average of data over different gait cycles indicated by cycleIndices
% - Synchronizes data to resample time
%
%------------------------------------------- INPUTS -------------------------------------------------------------------------------
% time                                  | Nx1 double array      | original time vector
% data                                  | NxM double array      | original data matrix    
% cycleIndices                          | Tx2 double array      | start & end indices for consecutive gait cycles
% resampTime                            | Rx1 double array      | time vector to resample the data to
% txColumn                              | integer               | optional: column of tx data (choose 0 if no tx data)
% debug                                 | boolean               | optional: creates debug figures
%
%------------------------------------------ OUTPUTS -------------------------------------------------------------------------------
% averaged_data                         | RxM double array      | array containing the averaged data
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 30/May/2025

% Last Update: Menthy Denayer
% Date: 30/May/2025 : Added documentation

%% Define Variables
Ncycles = size(cycleIndices, 1);                                            % number of gait cycles
Ncolumns = size(data,2);                                                    % number of columns for data
summed_data = zeros(length(resampTime), Ncolumns);                          % list to store averaged data

%% Loop over Data Columns & Gait Cycles
for colIdx = 1:Ncolumns                                                     % loop over data columns
    for cycleIdx = 1:Ncycles
        % extract time/data section representing 1 gait cycle
        startIdx = cycleIndices(cycleIdx, 1);                               % gait cycle start
        endIdx = cycleIndices(cycleIdx, 2);                                 % gait cycle end
        time_section = time(startIdx:endIdx);
        data_section = data(startIdx:endIdx, colIdx);

        % if pelvis tx included in data, subtract initial value from data 
        % for averaging
        if(txColumn == colIdx)
            data_section = data_section - data_section(1);
        end

        % synchronize data to resample time
        if ~all(isnan(data_section))
            synchronized_data = synchronizeData(resampTime, time_section, data_section);
        else
            Ndata = length(resampTime);
            synchronized_data = NaN(Ndata,1);
        end

        % sum data together over gait cycles
        summed_data(:,colIdx) = summed_data(:,colIdx) + synchronized_data; 
    end
end

%% Compute Average 
average_data = summed_data/Ncycles;

%% Debug Results
if(debug)
    for colIdx = 1:Ncolumns
        figure
        plot(resampTime, average_data(:,colIdx), "black")
    end
end

end