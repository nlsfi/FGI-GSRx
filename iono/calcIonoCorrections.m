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
function dIono = calcIonoCorrections(satSingle, pos, corrIonoData, refTime, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates the ionospheric delay
% 
% Parameters:
%   satSingle   -  Satellite info for one satellite
%   pos         - User position
%   corrIonoData        - Klobuchar iono model parameters
%   refTime     - Reference time for calculations
%   const       - Constants
%
% Returns:
%   dIono       - Ionospheric delay in meters  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iAlpha0 = corrIonoData.alpha0;
iAlpha1 = corrIonoData.alpha1;
iAlpha2 = corrIonoData.alpha2;
iAlpha3 = corrIonoData.alpha3;

iBeta0 = corrIonoData.beta0;
iBeta1 = corrIonoData.beta1;
iBeta2 = corrIonoData.beta2;
iBeta3 = corrIonoData.beta3;

% Calculate helping coordinates
[dLat,dLon,dAlt] = wgsxyz2lla(const, pos(1:3)');
dEle = satSingle.elev/180*pi;
dAzi = satSingle.azim/180*pi;
dwTowMs = refTime * 1000;

% Constants
INV_PI = 1/const.PI;
SPEED_OF_LIGHT = const.SPEED_OF_LIGHT;
SECONDS_IN_DAY = const.SECONDS_IN_DAY;

% SV elevation in semicircles.
es  = dEle * INV_PI;

% Receiver latitude in semicircles.
phu = dLat/180;

% Receiver longitude in semicircles.
lmu = dLon/180;             

% Don't compute ionospheric correction for SV's below the horizon.
if (es < 0.0)
    dIono=0.0;
else
    % Compute slant factor f.
    temp = 0.53 - es;
    f = 1.0 + 16.0*temp*temp*temp;

    % Use nocturnal value when ionospheric correction is unavailable
    dIono = f * 5.0e-9 * SPEED_OF_LIGHT + 0.5;

    % Compute Earth angle psi (semicircles).
    psi = 0.0137 / (es + 0.11) - 0.022;

    % Compute subionospheric latitude phi (semicircles).
    % Here dAzi is in radians.
    phi = phu + psi * cos(dAzi);

    % Limit phi to between +75 degrees and - 75 degrees.
    if (phi > 0.416)
        phi = 0.416;
    elseif (phi < -0.416)
        phi = -0.416;
    end;

    % Compute subionospheric longitude lmi (semicircles).
    lmi = lmu + psi * sin(dAzi) / cos(phi*pi);

    % Compute local time in seconds
    % = GMT + 43200 seconds per semicircle of longitude 
    sec = dwTowMs * 0.001;
    tlocal = sec + SECONDS_IN_DAY * 0.5 * lmi;

    if (tlocal >= SECONDS_IN_DAY)
        lMultiples = floor(tlocal / SECONDS_IN_DAY);
        tlocal = tlocal - SECONDS_IN_DAY * (lMultiples);
    elseif (tlocal < 0.0)
        lMultiples = floor((abs(tlocal)) / SECONDS_IN_DAY) + 1;
        tlocal = tlocal + SECONDS_IN_DAY * (lMultiples);
    end;

    % Compute subionospheric geomagnetic latitude phm (semicircles).
    phm = phi + 0.064 * cos((lmi - 1.617) * pi);
    phm2 = phm * phm;
    phm3 = phm2 * phm;

    % Diurnal maximum time delay: suma. Diurnal period: sumb.    
    suma = iAlpha0 + iAlpha1*phm + iAlpha2*phm2 + iAlpha3*phm3; 
    sumb = iBeta0 + iBeta1*phm + iBeta2*phm2 + iBeta3*phm3;
           
    if (suma < 0.0)
           suma = 0.0;
    end;

    if (sumb < 72000.0)
          sumb = 72000.0;
    end;

    if (sumb ~= 0.0) 
         xtemp = 2.0 * pi * (tlocal - 50400.0) / sumb;
    else 
         xtemp = 0.0;
    end;

    if (abs(xtemp) < 1.57)
         x2 = xtemp * xtemp;
         x4 = x2 * x2;
         temp = 1.0 - x2 * 0.5 + x4 * (1.0 / 24.0);
         dIono = f * (5.0e-9 + suma * temp) * SPEED_OF_LIGHT + 0.5;
    else 
         dIono = f * 5.0e-9 * SPEED_OF_LIGHT;
    end;
end;    




