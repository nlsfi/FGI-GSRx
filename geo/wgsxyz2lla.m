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

function [lat, lon, alt] = wgsxyz2lla( const, xyz )
% [lat, lon, alt] = WGSXYZ2LLA( const, xyz )
% input xyz [meters] shall have dimensions Nx3
% then lat [degrees], lon [degrees], alt [meters] will be Nx1 each

% Reference: P. Misra & P. Enge, "Global Positioning System: Signals, 
% Measurements, and Performance", 2nd ed., Appendix 3.A.1, pp. 115--116

%% WGS84 constants
A = const.EARTH_SEMIMAJORAXIS;
F = const.EARTH_FLATTENING; % note: the const parameter is the inverse flattening
E2 = (2-F)*F;

%% Input sanity check
if isvector( xyz )
    if length( xyz ) ~= 3
        error( 'Input is a vector of length %d, 3 expected', length( xyz ) );
    elseif iscolumn( xyz ) %size( xyz, 1 ) == 3
        xyz = xyz';       
    end                
elseif size( xyz, 2 ) ~= 3
    error( 'Input must be of size nx3, %d×%d encountered', ...
           size( xyz, 1 ), size( xyz, 2 ) );
end

% The actual conversion
lat = zeros( size( xyz, 1 ), 1 );
lon = atan2d( xyz(:, 2), xyz(:, 1) );

% The iteration of latitude and altitude is started at zero latitude
p = sqrt( sum( xyz(:, 1:2).^2, 2 ) );
for iteration = 1:10
    N = A ./ sqrt( 1 - E2 * sind( lat ).^2 );
    alt = p ./ cosd( lat ) - N;
    lat = atand( xyz(:, 3) ./ p ./ (1 - E2 * (N ./ (N + alt ) ) ) );
end