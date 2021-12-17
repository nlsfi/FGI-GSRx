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
    = beib1Satpos(transmitTime, prn, eph, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculation of Beidou satellite coordinates, clock corrections and velocities at 
% given time
%
% Inputs:
%   transmitTime    - transmission time
%   prn             - prn to be processed
%   eph             - ephemeridies of satellites
%   const               - Constants
%
% Outputs:
%   satPositions    - positions of satellites (in ECEF system [X; Y; Z;])
%   satClkCorr      - correction of satellites clocks
%   satT_GD         - B1 pseudorange group delay
%   satVelocity     - velocity of satellites (in ECEF system [VX; VY; VZ;])
%   satHealth       - Boolean satellite health flag. true for good satellites
%   satURA          - satellite user range accuracy
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% First ensure that ephemerides are available for the requested satellite
if isempty( eph(prn).IODE ) || isempty( eph(prn).IODC )
    satPositions = [NaN NaN NaN]';
    satVelocity = [NaN NaN NaN]';
    satT_GD = NaN;
    satClkCorr = NaN;
    satHealth = false;
    return;
end

% Call function for gps
[satPositions, satClkCorr, satT_GD, satVelocity] = mulSatpos(transmitTime, prn, eph, const);    

% If the broadcast health bit equals 0, the satellite is good
satHealth = eph(prn).SatH1 == 0;

% Ensure that the accuracy estimate is a floating point number and not int
%eph(prn).accuracy = double( eph(prn).accuracy );

% The mapping of accuracy index to standard deviation is the same as for GPS
if eph(prn).URAI < 6
    switch eph(prn).URAI
        case 1
            satURA = 2.8;
        case 3
            satURA = 5.7;
        case 5
            satURA = 11.3;
        otherwise
            satURA = 2^(1 + eph(prn).URAI/2);
    end
elseif eph(prn).URAI < 15
    satURA = 2^(eph(prn).URAI - 2);
else
    satURA = NaN;  % No accuracy prediction available
end