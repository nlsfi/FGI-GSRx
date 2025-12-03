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
function obsSingle = applyTropoCorrections(const, signalSettings, obsSingle, satSingle, navSolution)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the function for applying tropo corrections to the pseudoranges
%
% Inputs:
%   const               - Constants
%   signalSettings      - receiver configuration settings
%   obsSingle           - Observations for one epoch
%   satSingle           - satellite positions and velocities for one epoch
%   navSolutions        - Output from navigation (position, velocity, time,
%   dop etc)
%
% Outputs:
%   obsSingle           - Observations for one epoch
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if(signalSettings.enableTropoCorrections == false)
    return;
end

% We need user position
if(strcmp(navSolution.Pos.Flag,'GOOD_FOR_NAV') == 0) 
    return;
end

% Saastamoinen ZHD + simple map
ZHD_Saas = calcTropoSaastamoinenZHD(const, navSolution.Pos.xyz); 
SimpleMap = calcTropoSimpleMap(satSingle);
dTropo_HD = -ZHD_Saas * SimpleMap;

% Copy data
obsSingle.tropoCorr = dTropo_HD;
obsSingle.corrP = obsSingle.corrP + obsSingle.tropoCorr;








