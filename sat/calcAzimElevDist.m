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
function [az, el, dist] = calcAzimElevDist( const, ref_xyz, los_xyz )
% [az, el, dist] = calcAzimElevDist( const, origin_xyz, los_xyz )
% Computes the azimuth, elevation, and distance corresponding to 
% the line of sight vector(s) los_xyz as seen from the point origin_xyz.
% 
% Thus, the coordinates of the origin must be subtracted from the coordinates
% of the "target" to obtain the LOS vectors before calling this function!
%
% los_xyz [meters] shall have dimensions Nx3, then az [-180...180 deg], 
% el [-90...90 deg], and dist [meters] will each be Nx1. 
% origin_xyz shall be a vector of length 3. 
% North is zero azimuth, East is 90 deg.

% Reference: P. Misra & P. Enge, "Global Positioning System: Signals, 
% Measurements, and Performance", 2nd ed.

%% Input sanity check
if isvector( los_xyz )
    if length( los_xyz ) ~= 3
        error( 'xyz is a vector of length %d, 3 expected', length( los_xyz ) );
    elseif size( los_xyz, 1 ) == 3
        los_xyz = los_xyz';
    end                
elseif size( los_xyz, 2 ) ~= 3
    error( 'xyz must be of size n×3, %d×%d encountered', ...
           size( los_xyz, 1 ), size( los_xyz, 2 ) );
end

if ~isvector( ref_xyz ) || length( ref_xyz ) ~= 3
    error( 'ref_xyz must be a vector of length 3, %d×%d encountered', ...
           size( ref_xyz, 1 ), size( ref_xyz, 2 ) );
elseif norm( ref_xyz ) < 1e6
    warning( 'calcAzimElevDist:possibleLLAorigin', ...
             'Origin coordinates [%d %d %d] input as XYZ; sure they are not lat-lon-alt?', ...
             ref_xyz(1), ref_xyz(2), ref_xyz(3)  );
end

%% Construct the rotation matrix from XYZ to local level
[reflat, reflon] = wgsxyz2lla( const, ref_xyz );

R = [-sind( reflon )                  cosd( reflon )                  0;
     -sind( reflat ) * cosd( reflon )   -sind( reflat ) * sind( reflon )    cosd( reflat );
      cosd( reflat ) * cosd( reflon )    cosd( reflat ) * sind( reflon )    sind( reflat )];

%% Compute azimuth, elevation, and distance
% Transform xyz to local level coordinates
enu = los_xyz * R';

dist = sqrt( sum( enu.^2, 2 ) );
az = atan2d( enu(:, 1), enu(:, 2) );
el = atand( enu(:, 3) ./ sqrt( sum( enu(:, 1:2).^2, 2 ) ) );