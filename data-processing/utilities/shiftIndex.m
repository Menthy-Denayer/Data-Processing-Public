function shiftedData = shiftIndex(data, idx_shift, dir, debug)
%% shiftIndex - Shifts the data by the given index
% - Rotates data by given index
%
%------------------------------------------- INPUTS -------------------------------------------------------------------------------
% data                                  | NxM double array      | original data matrix    
% idx_shift                             | integer               | number of indices to shift
% dir                                   | +1/-1                 | shift direction: forward/backward
% debug                                 | boolean               | optional: creates debug figures
%
%------------------------------------------ OUTPUTS -------------------------------------------------------------------------------
% shiftedData                           | NxM double array      | array containing the shifted data
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 16/Sep/2025

% Last Update: Menthy Denayer
% Date: 16/Sep/2025 : Added documentation
    
%% Define Variables
idx_shift = round(idx_shift);                                               % round to make sure it is an integer
M = size(data, 2);                                                          % number of columns
N = size(data, 1);                                                          % number of rows
shiftedData = zeros(N, M);                                                  % empty matrix to store results
    
%% Shift the Data
if(dir > 0)
    for i = 1:M
        shiftedData(1:idx_shift, i) = data(end-idx_shift+1:end, i);
        shiftedData(idx_shift+1:end, i) = data(1:end-idx_shift, i);
    end
else
    for i = 1:M
        shiftedData(1:end-idx_shift, i) = data(idx_shift+1:end, i);
        shiftedData(end-idx_shift+1:end, i) = data(1:idx_shift, i);
    end
end

%% Debug Figure
if(debug)
    figure
    hold on
    plot(data,"red")
    plot(shiftedData,"blue")
    hold off
end
end