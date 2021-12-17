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
function [satPositions, satClkCorr, satT_GD, satVelocity, satHealth, satURA] ...
    = gpsl1Satpos(transmitTime, prn, eph, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculation of satellite coordinates, clock corrections and velocities at
% given time
%
% Inputs:
%   transmitTime    - transmission time
%   prn             - prn to be processed
%   eph             - ephemeridies of satellites
%   const           - Constants
%
% Outputs:
%   satPositions  - positions of satellites (in ECEF system [X; Y; Z;])
%   satClkCorr    - correction of satellites clocks
%   satT_GD       - L1 pseudorange group delay correction
%   satVelocity   - velocity of satellites (in ECEF system [VX; VY; VZ;])
%   satHealth     - Boolean satellite health flag. true for good satellites
%   satURA        - nominal RMS user range accuracy in meters
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% First ensure that ephemerides are available for the requested satellite
% if isempty( eph(prn).IODE_sf2 ) || isempty( eph(prn).IODE_sf3 ) ...
%         || isempty( eph(prn).IODC )
if isempty( eph(prn).C_rs ) || isempty( eph(prn).e ) ...
        || isempty( eph(prn).omega )
    satPositions = [NaN NaN NaN]';
    satVelocity = [NaN NaN NaN]';
    satT_GD = NaN;
    satClkCorr = NaN;
    satHealth = false;
    return;
end

% Call function for gps
[satPositions, satClkCorr, satT_GD, satVelocity] = mulSatpos(transmitTime, prn, eph, const);

% Check the six-bit health indication
% MSB 0 implies all nav data OK
satHealth = ~bitand( eph(prn).health, 2^5 );

% Ensure that the accuracy estimate is a floating point number and not int
eph(prn).accuracy = double( eph(prn).accuracy );

if eph(prn).accuracy <= 6
    switch eph(prn).accuracy
        case 1
            satURA = 2.8;
        case 3
            satURA = 5.7;
        case 5
            satURA = 11.3;
        otherwise
            satURA = 2^(1 + eph(prn).accuracy/2);
    end
elseif eph(prn).accuracy < 15
    satURA = 2^(eph(prn).accuracy - 2);
else
    satURA = NaN;  % No accuracy prediction available
end


