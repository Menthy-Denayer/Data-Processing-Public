function [virtualMarkerLabels, virtualMarkerData] = computePelvisVirtualMarkers(markerLabels, markerData)
%% computePelvisVirtualMarkers - Computes virtual pelvis markers
% - requires typical markers like ASIS, PSIS markers
% - requires virtual hip joint centre markers
% - estimates markers at the middle of:
%   o hip joint centres
%   o ASIS markers
%   o PSIS markers
%   o pelvis (based on mid ASIS & mid PSIS)
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% markerLabels                          | 1x6 string array      | Labels of existing pelvis markers
% markerData                            | Nx3x6 double array    | Time series marker data for all existing pelvis markers
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% virtualMarkerLabels                   | 1x4 string array      | Labels of estimated, virtual pelvis markers
% virtualMarkerData                     | Nx3x4 double array    | Time series marker data for estimated, virtual pelvis markers
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
%
%------------------------------------------------------------- TO DO's ------------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 29/Jul/2025

% Last Update: Menthy Denayer
% Date: 23/Aug/2025 : updated info

%% Define Variables
% virtual marker names
virtualMarkerLabels = ["midHJC", "midASI", "midPSI", "midPelvis"];

% find right labels
isLeft = contains(markerLabels,"L");
isRight = contains(markerLabels,"R");
isHJC = contains(markerLabels,"HJC");
isASI = contains(markerLabels,"ASI");
isPSI = contains(markerLabels,"PSI");

% find data
RHJCdata = markerData(:,:,isRight & isHJC);
LHJCdata = markerData(:,:,isLeft & isHJC);
RASIdata = markerData(:,:,isRight & isASI);
LASIdata = markerData(:,:,isLeft & isASI);
RPSIdata = markerData(:,:,isRight & isPSI);
LPSIdata = markerData(:,:,isLeft & isPSI);

%% Compute Virtual Markers
virtualMarkerData(:,:,1) = (RHJCdata + LHJCdata)/2;                         % mid HJC 
midASIdata = (RASIdata + LASIdata)/2;
virtualMarkerData(:,:,2) = midASIdata;                                      % mid ASI
midPSIdata = (RPSIdata + LPSIdata)/2;                                      
virtualMarkerData(:,:,3) = midPSIdata;                                      % mid PSI
virtualMarkerData(:,:,4) = (midASIdata + midPSIdata)/2;                     % mid Pelvis

end