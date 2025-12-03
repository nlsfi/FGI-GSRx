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
function [satPositions, satClkCorr, groupDelay, satVelocities, satHealth, satAcc] = glol1Satpos(transmitTime, prn, eph, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function calculates position, velocity and acceleration
% of the Glonass satellite at the transmitTime based on
% ephemeris data (eph).
%
% Inputs:
%   transmitTime        - time at which satellite position is calculated
%   prn                 - satellite to be processed
%   eph                 - satellites ephemerides
%   const               - Constants
%
% Outputs:
%   satPositions        - satellites positions
%   satClkCorr          - corrections for satellite clock
%   satVelocities       - satellites velocities
%   satHealth           - Satellite health flag. true for good satellites
%   satAcc              - mean square ephemeris error prediction
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Delta time between ephemeris issue time and current time.
deltat = (transmitTime) - (eph(prn).tb * 60); 

% Constants
c20 = const.C20; % 2nd zonal harmonic of ellipsoid

% These are slightly different values than in the ICD. 
% Max SV pos difference is anyhow just 2 cm
mu  = const.EARTH_GRAVCONSTANT; % Gravitational constant
ae  = const.EARTH_SEMIMAJORAXIS;	% Earth Semimajor axis
we  = const.EARTH_WGS84_ROT; % Earth rotation rate

% Perturbing accelerations:
acc(1) = eph(prn).xdotdot * 1000;
acc(2) = eph(prn).ydotdot * 1000;
acc(3) = eph(prn).zdotdot * 1000;

% Initial values
y0(1) = eph(prn).x * 1000;   %X
y0(2)= eph(prn).y * 1000;    %Y
y0(3)= eph(prn).z * 1000;    %Z
y0(4)= eph(prn).xdot * 1000; %VX
y0(5)= eph(prn).ydot * 1000; %VY
y0(6)= eph(prn).zdot * 1000; %VZ

tspan = [0 deltat];

% Solve the differential equation
[T,Y] = ode45(@orbit, tspan, y0);
y(1)     = Y(end,1);
y(2)     = Y(end,2);
y(3)     = Y(end,3);
y(4)    = Y(end,4);
y(5)    = Y(end,5);
y(6)    = Y(end,6);

satPositions     = y(1:3);
satVelocities    = y(4:6);
satAccelerations(1) = acc(1);
satAccelerations(2) = acc(2);
satAccelerations(3) = acc(3);
satTransmitTime            = deltat;

satClkCorr = - eph(prn).taun + eph(prn).gamman*(deltat);
groupDelay = 0;
satVelocities(4) = eph(prn).gamman;

% If the MSB of the health word Bn (3 bits) is set, the satellite is bad
% Note that decodeEphemeris() only saves this single bit
satHealth = eph(prn).Health ~= 0;

% The ICD defines the ephemeris errors as constants for GLONASS-M:
% along-track 7 m, cross-track 7 m, and radial 1.5 m
satAcc = norm( [7 7 1.5] );

% System of differential equations for a GLONASS satellite in  
% ECEF frame. Perturbing accelerations are assumed constant.
function dy = orbit(t,y)
   r = sqrt( (y(1)^2) + (y(2)^2) + (y(3)^2) );
   dy=zeros(6,1);
   dy(1)=y(4);
   dy(2)=y(5);
   dy(3)=y(6);
   dy(4)=(-mu/(r^3)*y(1) + ...
        3/2*c20*mu*(ae^2)/(r^5)*y(1)*(1 - 5/(r^2)*(y(3)^2)) + ...
        (we^2)*y(1) + 2*we*y(5) + acc(1));
   dy(5)=(-mu/(r^3)*y(2) + ...
        3/2*c20*mu*(ae^2)/(r^5)*y(2)*(1 - 5/(r^2)*(y(3)^2)) + ...
        (we^2)*y(2) - 2*we*y(4) + acc(2));
   dy(6)=(-mu/(r^3)*y(3) + ...
        3/2*c20*mu*(ae^2)/(r^5)*y(3)*(3 - 5/(r^2)*(y(3)^2)) + acc(3));
end
end
