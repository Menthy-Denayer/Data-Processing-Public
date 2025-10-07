function test_setup()
%% test_setup - checks if all the required toolboxes and repositories are installed
clear all
clc
close all

%% Define Variables
osimOK = false;
ezc3dOK = false;
matlabOK = false;

%% Check OpenSim Installation
% import OpenSim libraries
try 
    import org.opensim.modeling.*;
    OSIMversion = org.opensim.modeling.opensimCommon.GetVersion();
    fprintf(['(1/3) Succesfully imported OpenSim libraries! OpenSim Version is: ' char(OSIMversion) '\n'])
    osimOK = true;
catch ME
    fprintf(['(1/3) Could not import OpenSim libraries.\nError message: ' ME.message '\n'])
end

%% Check ezc3d Installation
ezc3dDIR = uigetdir("","Choose ezc3d directory.");                          % choose ezc3d directory
addpath(ezc3dDIR);

try
    ezc3dRead();
    fprintf('(2/3) Succesfully found ezc3d functions!\n')
    ezc3dOK = true;
catch ME
    fprintf(['(2/3) Could not find ezc3d functions.\nError message: ' ME.message '\n'])
end

%% Check MATLAB Toolboxes
try
    eul2rotm(rand(3,3));                                                    % check for robotics system toolbox
    fprintf('(3/3) Succesfully found the required MATLAB toolboxes!\n')
    matlabOK = true;
catch ME
    fprintf(['(3/3) Not all required toolboxes are installed.\nError message: ' ME.message '\n'])
end

%% Final Message
fprintf([repmat('-',1,80) '\n'])
if(osimOK & matlabOK & ezc3dOK)
    fprintf('All requirements are satisfied!\nThe repository is ready to use!\n')
else
    fprintf('Some installations are missing. The code might not be working correctly.\nPlease check the messages!\n')
end
fprintf([repmat('-',1,80) '\n'])
end