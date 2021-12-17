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
function [satPositions, satClkCorr, satT_GD, satVelocity, satHealth, satSISA] = gale1bSatpos(transmitTime, prn, eph, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculation of satellite coordinates, clock corrections and velocities at 
% given time
%
%   Inputs:
%       transmitTime  - transmission time
%       prn         - prn to be processed
%       eph           - ephemeridies of satellites
%
%   Outputs:
%       satPositions  - positions of satellites (in ECEF system [X; Y; Z;])
%       satClkCorr    - correction of satellites clocks
%       satVelocity   - velocity of satellites (in ECEF system [VX; VY; VZ;])
%       satHealth     - Boolean satellite health flag. true for good satellites
%       satSISA       - predicted SIS accuracy standard deviation
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% First check the navigation data validity and health status flags (shared for E1B/C)
% DVS: 0 = nav data valid;  1 = working without guarantee
% HS:  0 = OK; 1 = out of service; 2 = will be out of service; 3 = in test
satHealth = (eph(prn).E1B_DVS == 0) && (eph(prn).E1B_HS == 0);

% First ensure that ephemerides are available for the requested satellite
if isempty( eph(prn).IODE_sf2 ) || isempty( eph(prn).IODE_sf3 ) ...
        || isempty( eph(prn).IODC )
    satPositions = [NaN NaN NaN]';
    satVelocity = [NaN NaN NaN]';
    satT_GD = NaN;
    satClkCorr = NaN;
    return;
end

% Call function for gps
[satPositions, satClkCorr, satT_GD, satVelocity] = mulSatpos(transmitTime, prn, eph, const);  

% Single-frequency E1 users should use the I/NAV clock parameters and
% E1-E5b group delay.

% Cast the accuracy index to a floating point number
eph(prn).SISA = double( eph(prn).SISA );

if eph(prn).SISA <= 49
    satSISA = eph(prn).SISA / 100;
elseif eph(prn).SISA <= 74
    satSISA = 0.50 + 0.02 * (eph(prn).SISA - 50);
elseif eph(prn).SISA <= 99
    satSISA = 1 + 0.04 * (eph(prn).SISA - 75);
elseif eph(prn).SISA <= 125
    satSISA = 2 + 0.16 * (eph(prn).SISA - 100);
else
    % Note that values 126--254 are actually spare and only 255 is NAPA
    satSISA = NaN;
end