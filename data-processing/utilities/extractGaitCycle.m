function [cycleIndices] = extractGaitCycle(grf_data, threshold, debug)
%% extractGaitCycle - Indentify gait cycles by detecting heel strikes (GRFy > threshold)

%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% grf_data                              | Nx1 double array      | Data array of vertical GRFs
% threshold                             | double                | Threshold for heel strike detection
% debug                                 | boolean               | Bool to create debug plots
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% cycleIndices                          | Gx2 integer array     | Array of indices for gait cycle start/end
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
%
%------------------------------------------------------------ TO DO's -------------------------------------------------------------
% 
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 13/Jul/2025

% Last Update: Menthy Denayer
% Date: 23/Aug/2025 : Added info

%% Remove Spikes from GRF Data
grf_data = remove_spikes(grf_data, 50, threshold);

%% Define Variables
N = size(grf_data, 1);  % number of data elements
start_indices = [];     % empty list to store gait start indices
end_indices = [];       % empty list to store gait end indices
start = false;          % boolean to remember start/end detected

%% Check if Gait Already Started
if(grf_data(1) > threshold)
    start_indices = [start_indices 1];
    start = true;
end

%% Loop Over Data to Find Gait Cycles
for i = 2:N
    % if heel strike detected, save
    if(grf_data(i) > threshold && grf_data(i-1) < threshold)
        start_indices = [start_indices i-1];
        % check if gait already started, means previous cycle ended
        if(start)
            end_indices = [end_indices i-1];
        end
        start = true;
    end
end

%% Save Cycle Indices
NgaitCycles = min(length(start_indices), length(end_indices));

% Only return heel strikes if cycle never ended
if(isempty(end_indices))
    cycleIndices = start_indices;

% Return full gait cycle, if both start & ends detected
else
    cycleIndices = [start_indices(1:NgaitCycles)' end_indices(1:NgaitCycles)'];
end

%% Create Debug Plot
if(debug)
    figure
    hold on
    plot(1:N, grf_data, "Color", "black")
    xline(start_indices, "LineStyle", "--", "Color", "red")
    xline(end_indices, "LineStyle", "--", "Color", "blue")
    hold off
end

end

%% Function for Removing Spikes 
% remove short spikes that can mess up the gait detection
function proc_data = remove_spikes(data, minSpikeLength, threshold)

%% Define Variables
Ndata = length(data);
spikeList = zeros(Ndata,1);
spike_start = [];
start = false;

%% Loop over Data to Find Spikes
% if longer than the minimum length, flag as spike
for i = 1:Ndata
    if(data(i) > 0 && ~start)
        spike_start = i;
        start = true;
    elseif(data(i) == 0 && start)
        spike_end = i;
        spike_length = spike_end - spike_start;
        if(spike_length < minSpikeLength)
            spikeList(spike_start:spike_end) = 1;
        end
        start = false;
    end
end

%% Set Spikes to Zero
proc_data = data;
proc_data(spikeList==1) = 0;

% figure
% hold on
% plot(data)
% plot(proc_data)
% hold off

end