function [virtualMarkerLabels, virtualMarkerData] = computeFootVirtualMarkers(markerLabels, markerData)
%% computeFootVirtualMarkers - Computes virtual foot markers
% - requires typical markers like heel, toe & MT5 markers
% - requires virtual ankle joint centre markers
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% markerLabels                          | 1x8 string array      | Labels of existing foot markers
% markerData                            | Nx3x8 double array    | Time series marker data for all existing foot markers
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% virtualMarkerLabels                   | 1x10 string array     | Labels of estimated, virtual foot markers
% virtualMarkerData                     | Nx3x10 double array   | Time series marker data for estimated, virtual foot markers
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
%
%------------------------------------------------------------- TO DO's ------------------------------------------------------------
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 23/Aug/2025

% Last Update: Menthy Denayer
% Date: 23/Aug/2025 : updated info

%% Define Variables
% virtual marker names
virtualMarkerLabels = ["RHEEproj", "RAJCproj", "RMT5proj", "RTOEproj", "RTOEmid", "LHEEproj", "LAJCproj", "LMT5proj", "LTOEproj", "LTOEmid"];

% find right labels
isLeft = contains(markerLabels,"L");
isRight = contains(markerLabels,"R");
isHEE = contains(markerLabels,"HEE");
isAJC = contains(markerLabels,"AJC");
isMT5 = contains(markerLabels,"TOE");
isTOE = contains(markerLabels,"MT5");

% find data
RHEEdata = markerData(:,:,isRight & isHEE);
LHEEdata = markerData(:,:,isLeft & isHEE);
RAJCdata = markerData(:,:,isRight & isAJC);
LAJCdata = markerData(:,:,isLeft & isAJC);
RMT5data = markerData(:,:,isRight & isMT5);
LMT5data = markerData(:,:,isLeft & isMT5);
RTOEdata = markerData(:,:,isRight & isTOE);
LTOEdata = markerData(:,:,isLeft & isTOE);

%% Compute Virtual Markers
% project markers onto ground
RHEEdata(:,2) = 0; 
LHEEdata(:,2) = 0; 
RAJCdata(:,2) = 0; 
LAJCdata(:,2) = 0;  
RTOEdata(:,2) = 0;  
LTOEdata(:,2) = 0;  
RMT5data(:,2) = 0;  
LMT5data(:,2) = 0;  

virtualMarkerData(:,:,1) = RHEEdata;                                        % RHEE projected 
virtualMarkerData(:,:,2) = RAJCdata;                                        % RAJC projected 
virtualMarkerData(:,:,3) = RTOEdata;                                        % RTOE projected 
virtualMarkerData(:,:,4) = RMT5data;                                        % RMT5 projected 

virtualMarkerData(:,:,6) = LHEEdata;                                        % LHEE projected 
virtualMarkerData(:,:,7) = LAJCdata;                                        % LAJC projected 
virtualMarkerData(:,:,8) = LTOEdata;                                        % LTOE projected 
virtualMarkerData(:,:,9) = LMT5data;                                        % LMT5 projected 

virtualMarkerData(:,:,5) = (RTOEdata+RMT5data)/2;                           % R mid toe marker 
virtualMarkerData(:,:,10) = (LTOEdata+LMT5data)/2;                          % L mid toe marker 

end