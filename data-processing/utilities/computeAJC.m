function [virtualMarkerLabels, virtualMarkerData] = computeAJC(markerLabels, markerData)
%% computeFootVirtualMarkers - Computes virtual foot markers
% - requires typical markers like ANK & ANKmed
% - computes virtual ankle joint centre markers
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% markerLabels                          | 1x2 string array      | Labels of existing ankle markers
% markerData                            | Nx3x2 double array    | Time series marker data for all existing ankle markers
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% virtualMarkerLabels                   | 1x2 string array      | Labels of estimated, virtual ankle markers
% virtualMarkerData                     | Nx3x2 double array    | Time series marker data for estimated, virtual ankle markers
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
%
%------------------------------------------------------------- TO DO's ------------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 11/Sep/2025

% Last Update: Menthy Denayer
% Date: 11/Sep/2025 : updated info

%% Define Variables
% virtual marker names
virtualMarkerLabels = ["RAJC" "LAJC"];

% find right labels
isLeft = contains(markerLabels,"L");
isRight = contains(markerLabels,"R");
isANKmed = contains(markerLabels,"ANKmed");
isANK =  ~isANKmed;

% find data
RANKdata = markerData(:,:,isRight & isANK);
LANKdata = markerData(:,:,isLeft & isANK);
RANKmeddata = markerData(:,:,isRight & isANKmed);
LANKmedata = markerData(:,:,isLeft & isANKmed);

%% Compute Virtual Markers
virtualMarkerData(:,:,1) = (RANKdata+RANKmeddata)/2;                        % RAJC
virtualMarkerData(:,:,2) = (LANKdata+LANKmedata)/2;                         % LAJC

end