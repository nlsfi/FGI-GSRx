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

function [dphi, dlambda, h] = convXyz2Geod(const, XYZ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Subroutine to calculate geodetic coordinates latitude, longitude,
%         height given Cartesian coordinates X,Y,Z, and reference ellipsoid
%         values semi-major axis (a) and the inverse of flattening (finv).
%
%  The units of linear parameters X,Y,Z,a must all agree (m,km,mi,ft,..etc)
%  The output units of angular quantities will be in decimal degrees
%  (15.5 degrees not 15 deg 30 min). The output units of h will be the
%  same as the units of X,Y,Z,a.
%
%   Inputs:
% Inputs:
%   const   - Constants
%   xyz     - Cartesian coordinate vector
%
%   Outputs:
%       dphi        - latitude
%       dlambda     - longitude
%       h           - height above reference ellipsoid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

a = const.EARTH_SEMIMAJORAXIS;
finv = 1/const.EARTH_FLATTENING;%the inverse of flattening (finv)
X=XYZ(1);
Y=XYZ(2);
Z=XYZ(3);

h       = 0;
tolsq   = 1.e-10;
maxit   = 10;

% compute radians-to-degree factor
rtd     = 180/pi;

% compute square of eccentricity
if finv < 1.e-20
    esq = 0;
else
    esq = (2 - 1/finv) / finv;
end

oneesq  = 1 - esq;

% first guess
% P is distance from spin axis
P = sqrt(X^2+Y^2);
% direct calculation of longitude

if P > 1.e-20
    dlambda = atan2(Y,X) * rtd;
else
    dlambda = 0;
end

if (dlambda < 0)
    dlambda = dlambda + 360;
end

% r is distance from origin (0,0,0)
r = sqrt(P^2 + Z^2);

if r > 1.e-20
    sinphi = Z/r;
else
    sinphi = 0;
end

dphi = asin(sinphi);

% initial value of height  =  distance from origin minus
% approximate distance from origin to surface of ellipsoid
if r < 1.e-20
    h = 0;
    return
end

h = r - a*(1-sinphi*sinphi/finv);

% iterate
for i = 1:maxit
    sinphi  = sin(dphi);
    cosphi  = cos(dphi);
    
    % compute radius of curvature in prime vertical direction
    N_phi   = a/sqrt(1-esq*sinphi*sinphi);
    
    % compute residuals in P and Z
    dP      = P - (N_phi + h) * cosphi;
    dZ      = Z - (N_phi*oneesq + h) * sinphi;
    
    % update height and latitude
    h       = h + (sinphi*dZ + cosphi*dP);
    dphi    = dphi + (cosphi*dZ - sinphi*dP)/(N_phi + h);
    
    % test for convergence
    if (dP*dP + dZ*dZ < tolsq)
        break;
    end

    % Not Converged--Warn user
    if i == maxit
        fprintf([' Problem in TOGEOD, did not converge in %2.0f',...
            ' iterations\n'], i);
    end
end % for i = 1:maxit

dphi = dphi * rtd;

