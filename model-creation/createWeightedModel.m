function [x_l,y_l,inertia_l,x_r,y_r,inertia_r] = createWeightedModel(gaitModel, mass, height, width, thickness, descirc, desloc, markerRKNEtib, outputDir)
%% createWeightedModel - Creates a model with a weight added to the shank
%--------------------------------------------INPUTS--------------------------------------------
% gaitModel                             | OpenSim model         | OpenSim model to customize
% mass                                  | double                | mass of the added weight
% height                                | double                | height of the added weight
% width                                 | double                | width of the added weight
% thickness                             | double                | thickness of the added weight
% descirc                               | 1x2 double array      | left/right desired cirumference
% desloc                                | 1x2 double array      | left/right desired location (distance from KNE marker)
% markerRKNEtib                         | 1x3 double array      | position of the RKNE marker in the tibia frame
% outputDir                             | string                | directory to save the weighted models
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% x_l                                   | double                | left x-coordinate of the added weight
% y_l                                   | double                | left y-coordinate of the added weight
% inertia_l                             | 1x3 double array      | left computed inertia (Ixx, Iyy, Izz)
% x_r                                   | double                | right x-coordinate of the added weight
% y_r                                   | double                | right y-coordinate of the added weight
% inertia_r                             | 1x3 double array      | right computed inertia (Ixx, Iyy, Izz)

% Original Author: Menthy Denayer
% Date: 08/Oct/2025

% Last Update: Menthy Denayer
% Date: 08/Oct/2025 : Added descriptions

%% Import Libraries
import org.opensim.modeling.*;

%% com distance
[x_l, inertia_l] = computeWeightLocations(mass, descirc(1), height, width, thickness); x_l = x_l(2);
[x_r, inertia_r] = computeWeightLocations(mass, descirc(2), height, width, thickness); x_r = x_r(2);
y_l = markerRKNEtib(2)-desloc(1);
y_r = markerRKNEtib(2)-desloc(2);

%% Load OpenSim model
newModel = gaitModel.clone();
modelName = gaitModel.getName();
newModelName = string(modelName) + "_weighted" + string(mass) + "kg";
newModel.setName(newModelName);

%% Add obstacle to model
bodies = newModel.getBodySet(); % retrieve list of bodies in model

% Weight bodies (mass & inertia)
weight_body_right = Body('weights_right', mass, Vec3(0), Inertia(Vec3(inertia_r(2),inertia_r(3),inertia_r(1))));
newModel.addBody(weight_body_right)
weight_body_left = Body('weights_left', mass, Vec3(0), Inertia(Vec3(inertia_l(2),inertia_l(3),inertia_l(1))));
newModel.addBody(weight_body_left)

% Joints, weights added to underside of tibia 
weight_joint_right = WeldJoint('fixed',bodies.get("tibia_r"), Vec3(x_l,y_l,0), Vec3(0,0,0), weight_body_right, Vec3(0), Vec3(0)); % Fixed in space
newModel.addJoint(weight_joint_right);
weight_joint_left = WeldJoint('fixed',bodies.get("tibia_l"), Vec3(x_r,y_r,0), Vec3(0,0,0), weight_body_left, Vec3(0), Vec3(0)); % Fixed in space
newModel.addJoint(weight_joint_left);

% Geometry (visual), comment: important to do separate meshes for left/right
ball_size = 0.02;
sphere_mesh_right = Sphere(ball_size); sphere_mesh_right.setColor(Vec3((mass-1)*0.25,0,0));
weight_body_right.attachGeometry(sphere_mesh_right);
sphere_mesh_left = Sphere(ball_size); sphere_mesh_left.setColor(Vec3((mass-1)*0.25,0,0));
weight_body_left.attachGeometry(sphere_mesh_left);

%% Save new .osim file
% Finalize connections so that sockets connectees are correctly saved
newModel.finalizeConnections();

% Print the model to a XML file (.osim)
newModel.print(fullfile(outputDir, newModelName+".osim"));

return