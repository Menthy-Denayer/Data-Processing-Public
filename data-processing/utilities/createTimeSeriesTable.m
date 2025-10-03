function table = createTimeSeriesTable(labels, time, data)
%% createTimeSeriesTable - Creates an OpenSim Time Series Table
% - labels should not contain a label for the time column
% - number of labels should match the number of data columns
%
%------------------------------------------- INPUTS -------------------------------------------------------------------------------
% labels                                | 1xN string array      | Labels of the data columns
% time                                  | Mx1 double array      | Vector of time 
% data                                  | MxN double array      | Data matrix to save
%
%------------------------------------------ OUTPUTS -------------------------------------------------------------------------------
% table                                 | Osim TimeSeries Table | Table based on the data made from the OpenSim API
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% OpenSim MATLAB API (osimC3D)          | https://github.com/opensim-org/opensim-core/blob/main/Bindings/Java/Matlab/Utilities/osimC3D.m
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 31/May/2025

% Last Update: Menthy Denayer
% Date: 31/May/2025 : added information 

%% Import Libraries
import org.opensim.modeling.*

%% Create Table
table = TimeSeriesTable();

%% Assign column labels
labelsVec = StdVectorString();
for i = 1:length(labels)
    labelsVec.add(labels(i));
end
table.setColumnLabels(labelsVec);

%% Fill the table with data
Nrows = size(data,1);
for row = 1:Nrows
    rowVec = Vector().createFromMat(data(row,:)).transpose();
    table.appendRow(time(row), rowVec);
end

end