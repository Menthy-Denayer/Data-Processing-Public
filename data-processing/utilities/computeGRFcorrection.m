function corrFactor = computeGRFcorrection(settings)
%% computeGRFcorrection - Computes a correction factor based on a static trial
% - assumes the vertical forces should add up to be m*g in total
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% settings                              | struct                | Configuration structure with fields:
%   settings.grf_static_trial           | string                | Path to the static trial C3D file
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% corrFactor                            | double                | Correction factor for the force data
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
% OpenSim MATLAB API (osimC3D)          | https://github.com/opensim-org/opensim-core/blob/main/Bindings/Java/Matlab/Utilities/osimC3D.m
%
%------------------------------------------------------------- TO DO's ------------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 09/Oct/2025

% Last Update: Menthy Denayer
% Date: 09/Oct/2025 : updated info

%% Import OpenSim Libraries
import org.opensim.modeling.*

%% Variables
staticForceFile = settings.grf_static_trial;
c3dFile = ezc3dRead(char(staticForceFile));
bodyMass = c3dFile.parameters.PROCESSING.Bodymass.DATA;

%% Read C3D File
c3d = osimC3D(staticForceFile, 1);
c3d.rotateData('x', -90);

%% Load and Process C3D File
% Create osimC3D object and prepare data
c3d.convertMillimeters2Meters();                                            % Convert data to meters

%% Get Force Data
forceTable = c3d.getTable_forces();
forceLabels = forceTable.getColumnLabels();

%% Update Column Labels to OpenSim Conventions
updlabels = forceLabels;
for dataIdx = 0 : forceLabels.size() - 1
    label = char(forceLabels.get(dataIdx));
    if contains(label, 'f')
        label = strrep(label, 'f', 'ground_force_');
        label = [label '_v'];
    elseif contains(label, 'p')
        label = strrep(label, 'p', 'ground_force_');
        label = [label '_p'];
    elseif contains(label, 'm')
        label = strrep(label, 'm', 'ground_moment_');
        label = [label '_m'];
    end
    updlabels.set(dataIdx, label);
end

forceTable.setColumnLabels(updlabels);

%% Flatten the Force Table (Vec3 -> columns)
postfix = StdVectorString();
postfix.add('x'); postfix.add('y'); postfix.add('z');
forceTableFlat = forceTable.flatten(postfix);

%% Extract Desired Forces
forceStructFiltered = osimTableToStruct(forceTableFlat);

time = forceStructFiltered.time;
vy2 = forceStructFiltered.ground_force_2_vy;                                % correct force reading
vy3 = forceStructFiltered.ground_force_3_vy;                                % to be corrected force reading

Ndata = length(time);

Ftrue = repmat(bodyMass, Ndata, 1)*9.81;                                    % expected total force (body weight)
corrFactor = ( bodyMass*9.81 - mean(vy2) ) / mean(vy3);                     % correction factor
Fcorr = vy3*corrFactor;                                                     % corrected force

%% Message
diff = mean(Ftrue-vy2-vy3);
fprintf('Estimated difference found to be %.2f N.\n',diff)

%% Create Figures
% original data
% figure
% hold on
% plot(time, vy1)
% plot(time, vy2)
% plot(time, vy3)
% plot(time, vy4)
% legend()
% hold off

% corrected (summed) data
figure
hold on
plot(time, vy2+vy3)
plot(time, Ftrue, "k--")
plot(time, vy2 + Fcorr,"r")
legend(["Original Fy (tot)", "Expected Fy (tot)", "Corrected Fy (tot)"])
hold off

end