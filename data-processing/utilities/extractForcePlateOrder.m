function LRorder = extractForcePlateOrder(settings, GRFdata)
%% extractForcePlateOrder - Extract force plate foot order (left/right)
%
%------------------------------------------------------------- INPUTS -------------------------------------------------------------
% settings                              | struct                | Configuration structure with fields:
%   settings.gaitEvents                 | struct                | right/left heel strike timings
% GRFdata                               | double array (Nd x Np)| vertical GRF data in order of force plate hits
%
%------------------------------------------------------------- OUTPUTS ------------------------------------------------------------
% LRorder                               | string array (1 x Np) | string array of left/right foot order
%
%----------------------------------------------------------- REQUIREMENTS ---------------------------------------------------------
%
%------------------------------------------------------------- TO DO's ------------------------------------------------------------
% - improve force saving in left/right to be more general
%
%----------------------------------------------------------------------------------------------------------------------------------

% Original Author: Menthy Denayer
% Date: 12/July/2025

% Last Update: Menthy Denayer
% Date: 12/July/2025 : Added comments

%% Define Variables
Nforces = size(GRFdata,2)-1;
GRFtime = GRFdata(:,1);
LRorder = strings(1,Nforces);                                               % string array to save force plate order

%% Detect Heel Strikes Based on Forces
forceHeelStrikeIdxs = zeros(Nforces,1);                                     % array to save indices for heel strike
for forceIdx = 1:Nforces
    cycleIdx = extractGaitCycle(GRFdata(:,forceIdx+1), 1, false);           % find heel strike based on vertical GRF
    forceHeelStrikeIdxs(forceIdx) = cycleIdx(1);
end
heelStrikeTimes = GRFtime(forceHeelStrikeIdxs);                             % find times for heel strikes

%% Identify One Left/Right Force Plate
RHeelStrike = settings.gaitEvents.RHeelStrike(1);                           % heel strike from C3D file
LHeelStrike = settings.gaitEvents.LHeelStrike(1);                           % heel strike from C3D file

Rdiff = abs(heelStrikeTimes-RHeelStrike);
Ldiff = abs(heelStrikeTimes-LHeelStrike);

[~,RIdx] = min(Rdiff);                                                      % find closest time point
[~,LIdx] = min(Ldiff);                                                      % find closest time point

%% Check Whether Force Plates Are Alternating
% right & left should be even/uneven or otherway around
if(mod(RIdx,2) == mod(LIdx,2))
    warning("Force plates don't seem to be alternating!")
end

%% Complete Order
if(mod(RIdx,2) > 0)
    LRorder(1:2:end) = "r";
    LRorder(2:2:end) = "l";
else 
    LRorder(1:2:end) = "l";
    LRorder(2:2:end) = "r";
end
      
%% Debug
outputstr = repmat('%s ', 1, Nforces);                                      % replicate it to match the number of columns
outputstr = ['Identified force plate order is: ' outputstr '\n'];           % add a new line
fprintf(outputstr, LRorder.') 

end