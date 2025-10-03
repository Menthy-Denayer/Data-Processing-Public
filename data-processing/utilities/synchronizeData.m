function synchronized_data = synchronizeData(resampTime, time, data)
%% synchronizeData - Synchronize data to resample time
%
%------------------------------------------- INPUTS -------------------------------------------------------------------------------
% time                                  | Nx1 double array      | original time vector
% data                                  | NxM double array      | original data matrix    
% resampTime                            | Rx1 double array      | time vector to resample the data to
%
%------------------------------------------ OUTPUTS -------------------------------------------------------------------------------
% synchronized_data                     | RxM double array      | array containing the averaged data
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 30/May/2025

% Last Update: Menthy Denayer
% Date: 30/May/2025 : Added documentation

%% synchronize data w/ Time Vector to Resample Time
duration = time(end)-time(1);                                               % duration of data experiment
norm_time = (time-time(1))/duration;                                        % normalized time vector
synchronized_data = interp1(norm_time, data, resampTime', "linear");        % resampled data
end