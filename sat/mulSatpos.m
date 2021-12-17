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
function [satPositions, satClkCorr, satT_GD, satVelocity] = mulSatpos(transmitTime, prn, eph, const)    
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
%   satPositions    - positions of satellites (in ECEF system [X; Y; Z;])
%   satClkCorr      - correction of satellites clocks
%   satT_GD         - L1 pseudorange group delay correction
%   satVelocity     - velocity of satellites (in ECEF system [VX; VY; VZ;])
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Pi used in the GPS coordinate system
gpsPi = const.PI;
c = const.SPEED_OF_LIGHT; % Speed of light
WGS84oe = const.EARTH_WGS84_ROT; % WGS-84 value for the earths rotation velocity 
GravConstant = const.EARTH_GRAVCONSTANT; % WGS-84 value for the earths universal gravitation constant
F = -2*sqrt(GravConstant)/c^2;

dCrs=eph(prn).C_rs; 					%sine correction to radius
dCuc=eph(prn).C_uc; 					%cosine correction to lattitude
dCus=eph(prn).C_us; 					%sine correction to lattitude
dCic=eph(prn).C_ic; 					%cosine correction to inclination
dCrc=eph(prn).C_rc; 					%cosine correction to radius
dCis=eph(prn).C_is; 					%sine correction to inclination
dToe = eph(prn).t_oe;
dn=eph(prn).deltan; 				%mean motion difference from computed value
M0=eph(prn).M_0; 					%mean anomaly at reference time
ecc=eph(prn).e; 					%eccentricity
sqrta=eph(prn).sqrtA;				%square root of semimajor axis
dOmega=eph(prn).omega; 				%argument of perigee
dOmega0=eph(prn).omega_0; 			%right ascencion at reference time
dOmegaDot=eph(prn).omegaDot;	    %rate of right ascencion
dI0=eph(prn).i_0; 					%orbital inclination
dIdot=eph(prn).iDot;                  %rate of inclination angle
geoSV = eph(prn).geo;                 % Geostationary satellite

dA = sqrta * sqrta;
dN0 = sqrt(GravConstant /(dA * dA * dA));
Mdot = dN0;
Mdot = Mdot + dn;

% Find time difference 
dt = checkTime(const, transmitTime - eph(prn).t_oc);

% Calculate clock correction 
% Note: the group delay depends on the frequency and the observable, so we will
% NOT subtract it here yet.
satClkCorr = (eph(prn).a_f2 * dt + eph(prn).a_f1) * dt + ...
                         eph(prn).a_f0;

satT_GD = eph(prn).T_GD;                     

% Correct time difference 
time = transmitTime - satClkCorr;
tk  = checkTime(const, time - dToe);
                    
% Mean anomaly
M = M0 + Mdot*tk;
% Reduce mean anomaly to between 0 and 360 deg
M   = rem(M + 2*gpsPi, 2*gpsPi);

% Initial guess of eccentric anomaly
E = M;

% Iteratively compute eccentric anomaly 
for k=1:20

    sE = sin(E);
    cE = cos(E);
    dEdM = 1.0 / (1.0 - ecc * cE);
    dTemp  = (M - E + ecc * sE) * dEdM;

    if(abs(dTemp) < 1.0e-14)
        break;
    end;
    
    E = E + dTemp;
end;

% Reduce eccentric anomaly to between 0 and 360 deg
E   = rem(E + 2*gpsPi, 2*gpsPi);

% Compute relativistic correction term
relcorr = F * ecc * sqrta * sE;

dDeltaFreq    = eph(prn).a_f1 + 2.0*tk*eph(prn).a_f2;  
% TBA: dDeltaTime = eph(prn).a_f0 + tk*(eph(prn).a_f1 + tk*eph(prn).a_f2) + relcorr;
                     
Edot = dEdM * Mdot;

% Calculate the true anomaly and angle phi
sqrt1mee=sqrt(1-ecc^2);
P=atan2(sqrt1mee*sE,cE-ecc) + dOmega;

% Reduce phi to between 0 and 360 deg
P = rem(P, 2*gpsPi);

Pdot = sqrt1mee*dEdM*Edot;
Pdot2 = 2 * Pdot;

dtemp = 2 * P;
s2P = sin(dtemp);
c2P = cos(dtemp);

% Correct radius
R    = dA * (1.0 - ecc * cE);
Rdot = dA * ecc * sE * Edot;
R     = R + dCrs * s2P + dCrc * c2P;
Rdot  = Rdot + Pdot2 * (dCrs * c2P - dCrc * s2P);

% Correct inclination
I    = dI0;
I     = I + dIdot * tk + dCis * s2P + dCic * c2P;
Idot  = dIdot + Pdot2 * (dCis * c2P - dCic * s2P);

% Correct argument of latitude
U = P + dCus * s2P + dCuc * c2P;
Udot = Pdot + Pdot2 * (dCus * c2P - dCuc * s2P);

sU = sin(U);
cU = cos(U);

Xp    = R * cU;
Yp    = R * sU;
Xpdot = Rdot * cU - Yp * Udot;
Ypdot = Rdot * sU + Xp * Udot;

% Compute the angle between the ascending node and the Greenwich meridian
if(geoSV)
    L  = dOmega0 + tk * dOmegaDot;
    L = L - WGS84oe * dToe;
    Ldot = dOmegaDot - WGS84oe; % Does not know if this is correct
else
    L  = dOmega0 + tk * (dOmegaDot - WGS84oe);
    L = L - WGS84oe * dToe;
    Ldot = dOmegaDot - WGS84oe;
end

% Reduce to between 0 and 360 deg
L = rem(L + 2*gpsPi, 2*gpsPi);

sL = sin(L);
cL = cos(L);

sI = sin(I);
cI = cos(I);

dtemp = Yp * cI;

% Compute satellite coordinates 
satPositions(1) = Xp * cL - dtemp * sL;  
satPositions(2) = Xp * sL + dtemp * cL;
satPositions(3) = Yp * sI;

if(geoSV)
    % For GEO satellite position computation:
    minus5degreeInRadian = ((gpsPi*(-5))/180);
    R_x = [1                0                       0;
           0   cos(minus5degreeInRadian) sin(minus5degreeInRadian);
           0  -sin(minus5degreeInRadian) cos(minus5degreeInRadian)];

    R_z = [cos(WGS84oe*tk)  sin(WGS84oe*tk)     0;
           -sin(WGS84oe*tk) cos(WGS84oe*tk)     0;
                0                   0                 1];

    satPositions = (R_z*R_x)*satPositions';
end

% Include relativistic correction in clock correction 
satClkCorr = satClkCorr + relcorr;

dX = Xp * cL - dtemp * sL;    
dY = Xp * sL + dtemp * cL;
dZ = Yp * sI;

dtemp2 = dZ*Idot;
dtemp3 = Ypdot*cI;

satVelocity(1) = -Ldot*(dY) + Xpdot*cL - (dtemp3 + dtemp2)*sL;
satVelocity(2) = Ldot*(dX) + Xpdot*sL + (dtemp3 - dtemp2)*cL;
satVelocity(3) = dtemp*Idot + Ypdot*sI;
satVelocity(4) = dDeltaFreq;



