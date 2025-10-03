function [trc_file, mot_file] = exportC3D(settings)
%% exportC3D - Converts marker & force data from a .c3d file to an OpenSim-compatible .trc & .mot file.
% - Handles the marker & force data from the .c3d file.
% - Writes a clean .trc file that is OpenSim-compatible using the C3DtoTRC function.
% - Writes a clean .mot file that is OpenSim-compatible using the C3DtoMOT function.
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% settings                              | struct                | Configuration structure with fields:
%   settings.c3d_path_file              | string                | Full path to the .c3d input file
%   settings.use_COP_as_moments_point   | integer (0, 1, 2)     | Use Center of Pressure as reference for moments (default = 1)
%   settings.trc_results_dir            | string                | Path to save the resulting .trc file
%   settings.mot_results_dir            | string                | Path to save the resulting .mot file
%   settings.desired_markers            | Nx1 string arrary     | optional: Names of markers to extract
%   settings.export_original            | boolean               | optional: Export original data without filtering
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% trc_file                              | string                | Full path to the generated .mot file
% mot_file                              | string                | Full path to the generated .mot file
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% OpenSim MATLAB API (osimC3D)          | https://github.com/opensim-org/opensim-core/blob/main/Bindings/Java/Matlab/Utilities/osimC3D.m
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Couëdel Romane
% Date: 19/May/2025

% Last Update: Menthy Denayer
% Date: 23/May/2025 : Re-structuring code using OpenSim Table functions

%% Import OpenSim Java Libraries
import org.opensim.modeling.*

%% Load settings from input structure
% default setting if 'use_COP_as_moments_point' is not provided
if ~isfield(settings, 'use_COP_as_moments_point')
    settings.use_COP_as_moments_point = 1;
end

% assign settings
c3d_path_file = settings.c3d_path_file;
use_COP_as_moments_point = settings.use_COP_as_moments_point;

%% Define Results Directories
if(~isfield(settings,"trc_results_dir"))
    settings.trc_results_dir = "";
    fprintf("No results directory selected for saving the trc files. Using the current one instead!")
end

if(~isfield(settings,"mot_results_dir"))
    settings.mot_results_dir = "";
    fprintf("No results directory selected for saving the mot files. Using the current one instead!")
end

%% Define output file names
[~, filename, ~] = fileparts(c3d_path_file);
trc_file_original = fullfile(settings.trc_results_dir, strcat(filename, '_markers_original.trc'));
mot_file_original = fullfile(settings.mot_results_dir, strcat(filename, '_forces_COP_original.mot'));

%% Load the C3D file and rotate data to match OpenSim's coordinate system
c3d = osimC3D(c3d_path_file, use_COP_as_moments_point);
c3d.rotateData('x', -90);                                                   % Rotate around X-axis

%% Export marker data to initial TRC files using OpenSim API
if isfield(settings,"export_original")
    export_original = settings.export_original;
else
    export_original = false;
end

% save unaltered backup
if export_original
    try 
        c3d.writeTRC(char(trc_file_original)); 
    catch
        warning("Could not find .trc data from .c3d file.")
    end 

    try 
        c3d.writeMOT(char(mot_file_original));
    catch
        warning("Could not find .mot data from .c3d file.")
    end
end

%% Process Marker Data
try
    [trc_file,~] = C3DtoTRC(settings, c3d);
catch
    trc_file = '';
    warning("Did not process .trc files.")
end

%% Process Forces Data
try
    [mot_file,~] = C3DtoMOT(settings, c3d);
catch
    mot_file = '';
    warning("Did not process .mot files.")
end

end
