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
function [doppler,el,az] = getSatelliteDoppler(const, carrFreq, satSingle, pos)    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculation of satellite doppler frequencies
%
% Inputs:
%   const       - Constants
%   satSingle   - Satellite data for one epoch
%   carrFreq    - Signal carrier frequency
%   pos         - user position
%
% Outputs:
%   doppler     - satellite doppler frequencies
%   el          - elevation for satellite
%   az          - azimuth for satellite
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Constant
SPEED_OF_LIGHT = const.SPEED_OF_LIGHT;

% User satellite vector components
dx = satSingle.Pos(1) - pos(1);
dy = satSingle.Pos(2) - pos(2);
dz = satSingle.Pos(3) - pos(3);

% Calculate Azimuth, Elevation and distance to satellite
%[az, el, dist] = calcAzimElevDist(const, pos(1:3), [dx;dy;dz], 6378137, 298.257223563);
[az, el, dist] = calcAzimElevDist(const, pos(1:3), [dx;dy;dz]);

% Calculate satellite doppler
dopp = dx * satSingle.Vel(1) + dy * satSingle.Vel(2) + dz * satSingle.Vel(3);
dopp = dopp / sqrt(dx*dx+dy*dy+dz*dz);
doppler = -dopp*carrFreq/SPEED_OF_LIGHT;

%[az_sphere, el_sphere, dist] = calcAzimElevDistSphere(pos(1:3), [dx;dy;dz], 6370000);



