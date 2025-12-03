%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2015-2021 Finnish Geospatial Research Institute FGI, National
%% Land Survey of Finland. This file is part of FGI-GSRx software-defined
%% receiver. FGI-GSRx is a free software: you can redistribute it and/or
%% modify it under the terms of the GNU General Public License as published
%% by the Free Software Foundation, either version 3 of the License, or any
%% later version. FGI-GSRx software receiver is distributed in the hope
%% that it will be useful, but WITHOUT ANY WARRANTY, without even the
%% implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
%% See the GNU General Public License for more details. You should have
%% received a copy of the GNU General Public License along with FGI-GSRx
%% software-defined receiver. If not, please visit the following website 
%% for further information: https://www.gnu.org/licenses/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obsSingle = applyIonoCorrections(signalSettings, const, obsSingle, satSingle, navSolution, refTime,corrIonoData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the function for applying iono corrections to the pseudoranges
%
% Inputs:
%   signalSettings  - receiver configuration settings
%   const           - Constants
%   obsSingle       - Observations for one epoch
%   satSingle       - satellite positions and velocities for one epoch
%   navSolutions    - Output from navigation (position, velocity, time,
%   dop etc)
%   refTime         - Reference time 
%   corrIonoData    - contains ionosphere parameters
% Outputss:
%   obsSingle       - Observations for one epoch
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Corrections enabled ?
if(signalSettings.enableIonoCorrections == false)
    return;
end

% We need user position
if(strcmp(navSolution.Pos.Flag,'GOOD_FOR_NAV') == 0)
    return;
end

% Calcualte corrections
if strcmp(signalSettings.ionomodel,'gale1b')==1
    ionoCorr = neQuickIonoCorrection( obsSingle.tow*1000,obsSingle.week,navSolution.Pos.xyz,satSingle.Pos,signalSettings.carrierFreq,corrIonoData,const);
elseif strcmp(signalSettings.ionomodel,'ionex')==1    
    ionoCorr = ionexDelay(satSingle.Pos, navSolution.Pos.xyz , signalSettings.carrierFreq, obsSingle.tow, corrIonoData.tecTables, const);    
else    
    ionoCorr = calcIonoCorrections(satSingle, navSolution.Pos.xyz, corrIonoData, refTime, const); 
end      

% Copy results
obsSingle.ionoCorr = -ionoCorr;
obsSingle.corrP = obsSingle.corrP + obsSingle.ionoCorr;



