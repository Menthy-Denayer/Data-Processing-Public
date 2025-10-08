function [com_tot, inertia] = computeWeightLocations(mass, outer_circ, H, width, thick)
%% computeWeightLocations - Computes locations & inertia of the added weights
%--------------------------------------------INPUTS--------------------------------------------------------------------------
% mass                                  | double                | mass of the added weight
% outer_circ                            | double                | outer circumference of the added weight
% H                                     | double                | height of the added weight
% width                                 | double                | width of the added weight
% thick                                 | double                | thickness of the added weight
%
%------------------------------------------------------------- OUTPUTS -------------------------------------------------------
% com_tot                               | 1x3 double array      | total computed centre of mass vector wrt. centre of cylinder
% inertia                               | 1x3 double array      | total computed inertia (Ixx, Iyy, Izz)

% Original Author: Menthy Denayer
% Date: 08/Oct/2025

% Last Update: Menthy Denayer
% Date: 08/Oct/2025 : Added descriptions

%% Subject Measurements
shank_circ = 0.40;                                                          % m
outer_radius = outer_circ/(2*pi);
shank_radius = shank_circ/(2*pi);

%% Weight Measurements
weight_thick = thick;
pad_thick = width;                                                          % m
Npads = 4;          
theta_tot = Npads*pad_thick/outer_radius;                                   % theta range (rad)
theta_pad = theta_tot/Npads;                                                % theta range (rad) for each pad of weights

if theta_tot > 2*pi
    error("Nonsensical values")
end

%% COM Computation
% COM computation circle segment
com_r = compute_com_circle_segment(outer_radius, outer_radius-weight_thick, theta_pad);

%% Create Figure

% weight range
theta_min = pi/2-theta_tot/2;
theta_max = pi/2+theta_tot/2;

Thetacirc = linspace(-pi/2,3*pi/2,1000);
Xcirc = outer_radius*cos(Thetacirc);
Ycirc = outer_radius*sin(Thetacirc);
Xshank = shank_radius*cos(Thetacirc);
Yshank = shank_radius*sin(Thetacirc);
Xinner = (outer_radius-weight_thick)*cos(Thetacirc);
Yinner = (outer_radius-weight_thick)*sin(Thetacirc);

figure
hold on
grid on
axis equal

fill([Xcirc(theta_min < Thetacirc & Thetacirc < theta_max) rot90(Xinner(theta_min < Thetacirc & Thetacirc < theta_max ))'], [Ycirc(theta_min < Thetacirc & Thetacirc < theta_max) rot90(Yinner(theta_min < Thetacirc & Thetacirc < theta_max))'], "red")
plot(Xcirc, Ycirc, 'k--')

plot([0,outer_radius*cos(theta_max)],[0,outer_radius*sin(theta_max)],'k--')
com_list = zeros(Npads,2);
for i = 0:Npads-1
    theta_t = theta_min + theta_pad*i;
    plot([0,outer_radius*cos(theta_t)],[0,outer_radius*sin(theta_t)],'k--')

    com_list(i+1,:) = [com_r*cos(theta_t+theta_pad/2) com_r*sin(theta_t+theta_pad/2)];
    plot(com_list(i+1,1), com_list(i+1,2),"Marker","o","MarkerFaceColor","blue","MarkerEdgeColor","blue")
end

fill(Xshank, Yshank, "black", "FaceAlpha", 0.1, "EdgeColor", "none")
com_tot = mean(com_list);
plot(com_tot(1), com_tot(2), "Marker", "o", "MarkerFaceColor", "magenta")
text(0,outer_radius+0.01,"Front", "HorizontalAlignment","center")

xlim([-0.1, 0.1])
ylim([-0.1 0.1])
xticklabels("")
yticklabels("")

legend(["Weight Pads Covered", "Outer Circumference Weights", "", "", "Estimated Pad COM", repmat("",1,Npads*2-2), "Shank Cross Section", "Total Estimated COM"], "Location", "bestoutside")
hold off

%% Compute Inertia
dCOM = com_tot(2);
max_r = outer_radius;
min_r = outer_radius - weight_thick;
[Ixx,Iyy,Izz] = compute_inertia_cilinder_segment(mass, max_r, min_r, theta_max, theta_min, dCOM, H);
inertia = [Ixx, Iyy, Izz];

%% Functions
function com_r = compute_com_circle_segment(max_r, min_r, theta)

    A_out = max_r^2 * theta/2;
    A_in = min_r^2 * theta/2;

    com_r_out = 2/3 * max_r * sin(theta/2)/(theta/2);
    com_r_in = 2/3 * min_r * sin(theta/2)/(theta/2);

    com_r = (A_out * com_r_out - A_in * com_r_in)/(A_out - A_in);
end
    
function [Ixx, Iyy, Izz] = compute_inertia_cilinder_segment(mass, max_r, min_r, theta_max, theta_min, dCOM, H)

    theta = theta_max-theta_min;

    I1 = mass*(max_r^2+min_r^2)/4 + mass*H^2/12;
    I2 = mass*(max_r^2+min_r^2)/4*sin(2*pi-theta)/theta;                    
           
    Ixx = I1 - I2 - mass * dCOM^2;
    Iyy = I1 + I2;
    Izz = mass * (max_r^2+min_r^2)/2 - mass * dCOM^2;

end


end