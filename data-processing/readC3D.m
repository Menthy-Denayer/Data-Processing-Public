function output_files = readC3D(settings)
%% readC3D - Reads C3D data and prepares OpenSim-compatible files
% - All output files are saved in the directory specified by settings.results_directory.
% - Marker data is exported in two versions: raw (for scaling) and interpolated (for IK).
% - Force plate data (from Kistler) is converted from millimeters to meters.
% - Marker coordinates are not rescaled — this assumes that marker data is already in meters.
%
%------------------------------------------- INPUTS -------------------------------------------
% settings                              | struct                | Configuration structure with fields:
%   settings.c3d_path_file              | string                | Full path to the input .c3d file
%   settings.results_directory          | string                | Directory to save the processed output files
%   settings.desired_markers            | Nx1 string arrary     | optional: names of markers to extract
%   settings.use_COP_as_moments_point   | double (0,1,2)        | optional: use COP as reference for moments (default = 1)
%   settings.markers_lowpassFilter      | boolean               | optional: lowpass filter the marker data
%   settings.markers_lowpassFreq        | double                | optional: lowpass frequency limit 
%   settings.markers_lowpassFilterOrder | integer               | optional: lowpass filter order
%   settings.markers_max_gap            | double                | optional: max gap size to interpolate
%   settings.add_hip_virtual_markers    | boolean               | optional: estimate virtual hip markers
%   settings.add_foot_virtual_markers   | boolean               | optional: estimate virtual foot markers
%   settings.desired_forces             | Nx1 integer array     | optional: list of desired forces (indices)
%   settings.forces_lowpassFilter       | boolean               | optional: lowpass filter the force data
%   settings.forces_threshold           | double                | optional: threshold for vertical GRF to be non-zero
%   settings.forces_lowpassFreq         | double                | optional: lowpass frequency limit 
%   settings.forces_lowpassFilterOrder  | integer               | optional: lowpass filter order
%   settings.emg_desired_channels       | Nx1 string array      | optional: list of EMG channels to extract
%   settings.emg_c3d_identifier         | string                | optional: identifier for EMG channels in C3D data        
%   settings.emg_bandpassFilterOrder    | integer               | optional: bandpass filter order
%   settings.emg_lowpassFilterOrder     | integer               | optional: lowpass filter order
%   settings.emg_bandpassFreqLow        | double                | optional: bandpass lower frequency limit               
%   settings.emg_bandpassFreqHigh       | double                | optional: bandpass higher frequency limit   
%   settings.emg_lowpassFreq            | double                | optional: lowpass frequency limit   
%   settings.emg_normalize              | boolean               | optional: normalize EMG signal to max value
%
%------------------------------------------ OUTPUTS -------------------------------------------
% output_files                         | struct       | Structure containing full paths to generated files:
%   output_files.markers               | string       | Path to the .trc file with processed marker data 
%   output_files.forces                | string       | Path to the .mot file with processed ground reaction forces
%   output_files.emg                   | string       | Path to the .sto file with processed EMG data 
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% ezc3d toolbox                         | https://github.com/pyomeca/ezc3d
% OpenSim MATLAB API (osimC3D)          | https://github.com/opensim-org/opensim-core/blob/main/Bindings/Java/Matlab/Utilities/osimC3D.m
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Couëdel Romane
% Date: 19/May/2025

% Last Update: Menthy Denayer
% Date: 25/May/2025 : Replaced c3d_2_trc & c3d_2_mot functions to improve usability

%% Import OpenSim Libraries
import org.opensim.modeling.*

%% Extract and Save Marker & Force Data
% uses the C3DtoTRC & C3DtoMOT functions & the OpenSim C3D function
trc_file = '';
mot_file = '';

% try
%     [trc_file, mot_file] = exportC3D(settings);
% catch ME
%     warning(ME.identifier, 'Failed to extract marker & force data: %s', ME.message);
% end

%% Extract and Save EMG Data
% uses the ezc3d library
emg_file = '';
try
    [emg_file,~] = EMGtoSTO(settings);
catch ME
    warning(ME.identifier, 'Failed to extract EMG data: %s', ME.message);
end

%% Return List of Generated Files
output_files = struct( ...
    'markers', trc_file, ...
    'forces', mot_file, ...
    'emg', emg_file);

disp('Data successfully extracted and saved.');

end


