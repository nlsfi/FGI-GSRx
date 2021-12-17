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
function xyz = wgslla2xyz(const, wlat, wlon, walt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function returns the equivalent WGS84 XYZ coordinates (in meters) for a
% given geodetic latitude "lat" (degrees), longitude "lon" 
% (degrees), and altitude above the WGS84 ellipsoid
% in meters.  Note: N latitude is positive, S latitude
% is negative, E longitude is positive, W longitude is
% negative.
%
% Inputs:
%   const   - Constants
%   wlat    - WGS 84 latitude
%   wlon    - WGS84 longitude
%   walt    - WGS84 altitude
%
% Outputs:
%   xyz - Cartesian coordinate vector
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
A_EARTH = const.EARTH_SEMIMAJORAXIS;
flattening = const.EARTH_FLATTENING;

NAV_E2 = (2-flattening)*flattening; % also e^2
deg2rad = pi/180;

slat = sin(wlat*deg2rad);
clat = cos(wlat*deg2rad);
r_n = A_EARTH/sqrt(1 - NAV_E2*slat*slat);
xyz = [ (r_n + walt)*clat*cos(wlon*deg2rad);  
        (r_n + walt)*clat*sin(wlon*deg2rad);  
        (r_n*(1 - NAV_E2) + walt)*slat ];



