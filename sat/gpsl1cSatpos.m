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
function [satPositions, satClkCorr, satT_GD, satVelocity, satHealth, satURA] = gpsl1cSatpos(transmitTime, prn, eph, const)
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
if isempty( eph(prn).C_rs ) || isempty( eph(prn).e ) || isempty( eph(prn).omega )
    satPositions = [NaN NaN NaN]';
    satVelocity = [NaN NaN NaN]';
    satT_GD = NaN;
    satClkCorr = NaN;
    satHealth = false;
    return;
end

% Call function for GPS; TBA: Integrate this function into mulSatpos to reduce code repetition
% [satPositions, satClkCorr, satT_GD, satVelocity] = mulSatpos(transmitTime, prn, eph, const);

% Constants----------------------------------
gpsPi = const.PI;
c = const.SPEED_OF_LIGHT; % Speed of light
WGS84oe = const.EARTH_WGS84_ROT; % WGS-84 value for the earths rotation velocity 
GravConstant = const.EARTH_GRAVCONSTANT; % WGS-84 value for the earths universal gravitation constant
F = -2*sqrt(GravConstant)/c^2;
gpsA_REF = const.A_REF;
gpsOmega_REFDot = const.OMEGA_REFDOT;

% Epheremis parameters -----------------------
dC_rs=eph(prn).C_rs; 					    % Sine correction to radius
dC_uc=eph(prn).C_uc; 					    % Cosine correction to lattitude
dC_us=eph(prn).C_us; 					    % Sine correction to lattitude
dC_ic=eph(prn).C_ic; 					    % Cosine correction to inclination
dC_rc=eph(prn).C_rc; 					    % Cosine correction to radius
dC_is=eph(prn).C_is; 					    % Sine correction to inclination
dt_oe = eph(prn).t_oe;                      % Reference time ephemeris & clock data
ddeltan_0=eph(prn).deltan_0; 		        % Mean motion difference
ddeltan_0Dot = eph(prn).deltan_0Dot;        % Rate of mean motion difference
dM_0=eph(prn).M_0; 					        % Mean anomaly at reference time
de=eph(prn).e; 					            % Eccentricity
ddeltaA = eph(prn).deltaA;                  % Semi-major axis difference at reference time
dADot = eph(prn).ADot;                      % Change rate of semi-major axis
ddeltaOmegaDot = eph(prn).deltaOmegaDot;    % Rate of right ascension difference
da_f0 = eph(prn).a_f0;                      % SV clock bias correction
da_f1 = eph(prn).a_f1;                      % SV clock drift correction
da_f2 = eph(prn).a_f2;                      % SV clock drift rate correction
dISC_L1CD = eph(prn).ISC_L1CD;              % Intersignal correction for GPS L1C data channel
dISC_L1CP = eph(prn).ISC_L1CP;              % Intersignal correction for GPS L1C pilot channel
domega=eph(prn).omega; 				        % Argument of perigee
dOmega_0=eph(prn).Omega_0; 			        % Longitude of ascending node of orbit plane at weekly epoch 
di_0=eph(prn).i_0; 					        % Orbital inclination
dIDOT=eph(prn).IDOT;                        % Rate of inclination angle


% Calculated parameters ------------------------

% Find time difference 
dt = checkTime(const, transmitTime - dt_oe);

% Calculate SV clock offset
satClkCorr = (da_f2 * dt + da_f1) * dt + da_f0;

% Calculate SV signal group delay for GPS L1C pilot; Look for ICD GPS-800J page 55 for more information
satT_GD = eph(prn).T_GD - dISC_L1CP;      

% Corrected SV time 
time = transmitTime - satClkCorr;
t_k  = checkTime(const, time - dt_oe);

A_0 = gpsA_REF + ddeltaA;                       % Semi-major axis at reference time
A_k = A_0 + dADot*t_k;                          % Semi-major axis

% Mean motion (rad/sec)
n_0 = sqrt(GravConstant/A_0^3);                 % Computed mean motion    
deltan_A = ddeltan_0 + ddeltan_0Dot*t_k/2 ;     % Mean motion differene
n_A = n_0 + deltan_A;                           % Corrected mean motion

% Mean anomaly
M_k = dM_0 + n_A*t_k;
M_k = rem(M_k + 2*gpsPi, 2*gpsPi);              % Reduce mean anomaly to be between 0 and 360 deg

% ompute eccentric anomaly iteratively
E_k = M_k;                                      % Initial eccentric anomaly value       
for k=1:20

    sE = sin(E_k);
    cE = cos(E_k);
    dEdM = 1.0 / (1.0 - de * cE);
    dTemp  = (M_k - E_k + de * sE) * dEdM;

    if(abs(dTemp) < 1.0e-14)
        break;
    end
    
    E_k = E_k + dTemp;
end

% Reduce eccentric anomaly to be between 0 and 360 deg
E_k   = rem(E_k + 2*gpsPi, 2*gpsPi);

% True anomaly computation
rde = sqrt((1+de)/(1-de));
v_k = 2*atan(rde*tan(E_k/2));

% Argument of latitude
Phi_k = v_k + domega;

su_k = dC_us *sin(2*Phi_k) + dC_uc *cos(2*Phi_k);       % Argument of latitude correction
sr_k = dC_rs *sin(2*Phi_k) + dC_rc *cos(2*Phi_k);       % Radial correction
si_k = dC_is *sin(2*Phi_k) + dC_ic *cos(2*Phi_k);       % Inclination correction

u_k = Phi_k + su_k;                                     % Corrected argument of latitude
r_k = A_k*(1-de*cos(E_k))+sr_k;                         % Corrected radius
i_k = di_0 + dIDOT*t_k + si_k;                          % Corrected inclination

% SVs position on its orbital plane
x_ko = r_k*cos(u_k);                     
y_ko = r_k*sin(u_k);

% Rate of right ascension
OmegaDot = gpsOmega_REFDot + ddeltaOmegaDot;

% Longitude of ascending node
Omega_k = dOmega_0 + (OmegaDot-WGS84oe)*t_k - WGS84oe*dt_oe;
Omega_k = rem(Omega_k + 2*gpsPi, 2*gpsPi);              % Reduce the value to be between 0 and 360 deg

% ECEF coordinates of SV antenna phase center
x_k = x_ko * cos(Omega_k)-y_ko*cos(i_k)*sin(Omega_k);
y_k = x_ko * sin(Omega_k)+y_ko*cos(i_k)*cos(Omega_k);
z_k = y_ko*sin(i_k);

% SV Velocity
E_kDot = n_A/(1-de*cos(E_k));                                       % Eccentric anomaly rate
v_kDot = E_kDot*sqrt(1-de^2)/(1-de*cos(E_k));                       % True anomaly rate
cIDOT = dIDOT + 2*v_kDot*(dC_is*cos(2*Phi_k)-dC_ic*sin(2*Phi_k));   % Corrected inclination angle rate
u_kDot = v_kDot*(1+2*(dC_us*cos(2*Phi_k)-dC_uc*sin(2*Phi_k)));      % Corrected argument of latitude rate

% Corrected radius rate
r_kDot = dADot*(1-de*cos(E_k)) + de*A_k*E_kDot*sin(E_k) +...
         2*v_kDot*(dC_rs*cos(2*Phi_k)-dC_rc*sin(2*Phi_k));

% Longitude of ascending node rate
Omega_k_Dot = OmegaDot - WGS84oe;

% In-plane x and y velocities
x_kDoto = r_kDot*cos(u_k)-r_k*u_kDot*sin(u_k);
y_kDoto = r_kDot*sin(u_k)+r_k*u_kDot*cos(u_k);

% ECEF velocitites
x_kDot = -x_ko*Omega_k_Dot*sin(Omega_k) + x_kDoto*cos(Omega_k) -...
            y_kDoto*sin(Omega_k)*cos(i_k) - y_ko*...
            (Omega_k_Dot*cos(Omega_k)*cos(i_k)-cIDOT*sin(Omega_k)*sin(i_k));
y_kDot = x_ko*Omega_k_Dot*cos(Omega_k) + x_kDoto*sin(Omega_k) +...
            y_kDoto*cos(Omega_k)*cos(i_k) - y_ko*...
            (Omega_k_Dot*sin(Omega_k)*cos(i_k)+cIDOT*cos(Omega_k)*sin(i_k));
z_kDot = y_kDoto*sin(i_k)+y_ko*cIDOT*cos(i_k);

% TBA: acceleration calculations

% Satellite position return values
satPositions(1) = x_k;
satPositions(2) = y_k;
satPositions(3) = z_k;

% Compute relativistic correction term
relcorr = F * de * sqrt(A_k) * sin(E_k);

% Include relativistic correction in clock correction 
satClkCorr = satClkCorr + relcorr;

% Satellite velocity and clock drift rate
satVelocity(1) = x_kDot;
satVelocity(2) = y_kDot;
satVelocity(3) = z_kDot;
satVelocity(4) = da_f1 + 2.0*t_k*da_f2;

% Check the six-bit health indication; % MSB 0 implies that all nav data is OK
satHealth = 1-eph(prn).health;

% Ensure that the accuracy estimate is a floating point number and not int
eph(prn).URA_ED = double( eph(prn).URA_ED );

if eph(prn).URA_ED <= 6
    switch eph(prn).URA_ED
        case 1
            satURA = 2.8;
        case 3
            satURA = 5.7;
        case 5
            satURA = 11.3;
        otherwise
            satURA = 2^(1 + eph(prn).URA_ED/2);
    end
elseif eph(prn).URA_ED < 15
    satURA = 2^(eph(prn).URA_ED - 2);
else
    satURA = NaN;  % No accuracy prediction available
end


