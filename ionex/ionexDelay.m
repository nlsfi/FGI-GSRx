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
function delay =  ionexDelay( svPosition, receiverPosition, frequency, tow, ...
                              ionexTables, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the ionospheric delay for one satellite position.
%  Use parsed IONEX files to estimate to interpolate and ionospheric delay to
%  a piercing point that correponds to the LOS vector between given receiver
%  position and satellite position at a particular time instant.
%
%  ionexTables is the struct returned by the function parseIonex with the
%  desired IONEX file.
%
%  Positions should be in meters, frequency in Hertz, and tow in seconds.
%
%  The delay is in meters.
%
% Input:
%   svPosition       - satellite position vector
%   receiverPosition - Receiver position vector
%   frequency        - Frequency of signal (Hz)
%   tow              - Current time of week (sec)
%   ionexTables      - Table with TEC counts
%   const            - constants used in GNSS navigation computation
% Output:
%   delay            - Ionospheric delay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Make sure that position vectors are row vectors
if size(receiverPosition,1) > 1
  receiverPosition = receiverPosition';
end
if size(svPosition,1) > 1
  svPosition = svPosition';
end

% TEC units in IONEX files. One TECU is 1e16.
ionexTecu = 1e15;
% Find the piercing point
height = ionexTables.height;
try
    [lat, lon, angle] = findPiercing(receiverPosition, svPosition, height,const);
    % Get the vertical TEC to the piercing point
    vtec = getVtec(ionexTables, tow, lat, lon);
    % Compute the slant TEC value
    slantTec =  vtec / sin(angle/180*pi);
    % Compute the delay in meters
    delay = 40.30 * slantTec * ionexTecu / frequency^2;
catch
    delay = 0;
end

end


function [lat,lon,angle] = findPiercing(receiverPosition, svPosition, ...
                                        targetHeight,const)
%FINDPIERCING Get piercing point for one LOS vector.
%  The piercing point is computed to the given height.

los = svPosition - receiverPosition;
los = los/norm(los);

[~,~,height] = wgsxyz2lla(const,receiverPosition);
piercingPoint = receiverPosition;
losStep = targetHeight - height;
counter = 1;
while counter < 15 && abs(height - targetHeight) > 10
  previousHeight = height;
  piercingPoint = piercingPoint + losStep*los;
  [~,~,height] = wgsxyz2lla(const,piercingPoint);
  % Update losStep according to how much we made progress
  losStep = losStep * (targetHeight - height) / (height - previousHeight);
end

if abs(height - targetHeight > 10)
  error('Could not find a suitable piercing point');
end

% FIXME: These should probably be geocentric latitude and longitude
[lat,lon,~] = wgsxyz2lla(const,piercingPoint);
% The angle at which the LOS pierces the ellipse at targetHeight
direction = svPosition - piercingPoint;
[~,angle,~] = calcAzimElevDist(const,piercingPoint', direction');

end


function vtec = getVtec(ionexTables, tow, lat, lon)
%GETVTEC Obtain interpolated the TEC value to a piercing point.

lon = mod(lon, 360);

latStep = ionexTables.latStep;
lonStep = ionexTables.lonStep;
timeStep = ionexTables.timeStep;
% Earth rotation rate [rad/s]
OmegaEDot = 7.2921151467e-5;
% Find the bordering times
[adjTimes, timeDiff] = findAdjacent(ionexTables.tows, tow, 1);
% Find the bordering latitudes
[adjLat, latDiff] = findAdjacent(ionexTables.latitudes, lat, 2);
% Compute TEC values to tow bordering time values
for i=[1,2]
  % Rotate the longitudes to the new time
  % i.e., if time increases, smaller longitude values correspond to TEC
  % values of larger longitudes.
  if i == 1
    dLon = -OmegaEDot * timeDiff(i) / pi*180;
  else
    dLon = OmegaEDot * timeDiff(i) / pi*180;
  end
  lons = mod(ionexTables.longitudes + dLon, 360);
  % Find the bordering longitude values
  [adjLon, lonDiff] = findAdjacent(lons, lon, 3);
  % Take only four TEC values around the current point
  currentMap = ionexTables.maps(adjLat, adjLon, adjTimes(i));
  % Interpolate between the four points
  tecs(i) = interpolateTecMap(currentMap, latDiff, lonDiff, latStep, lonStep);
end

vtec = (tecs(1)*timeDiff(2) + tecs(2)*timeDiff(1))/timeStep;

end


function [neighborIdxs, diffs] =  findAdjacent(collection, value, kind)
%FINDADJACENT Get the neighboring item indices from a collection.
%  Kind refers to the type of collection. 1 denotes time collection,
%  2 denotes latitudes, and 3 longitudes. Latitudes are expected to be in
%  descending order. Longitudes can have a discontinuity around 360 degrees.

% Find the closest index
[~,closest] = min( abs(collection - value) );
if (kind ~= 2 && collection(closest) > value) || ...
   (kind == 2 && collection(closest) < value)
  prevIdx = closest - 1;
  nextIdx = closest;
else
  prevIdx = closest;
  nextIdx = closest + 1;
end

diffs = abs([value-collection(prevIdx), value-collection(nextIdx)]);
% Adjust too large longitude value differences
if kind == 3 && (diffs(1) > 180 || diffs(2) > 180)
  if diffs(1) > 180
    diffs(1) = abs( 360 - diffs(1) );
  elseif diffs(2) > 180
      diffs(2) = abs( 360 - diffs(2) );
  end
end

neighborIdxs = [prevIdx, nextIdx];

end


function tec = interpolateTecMap(tecMap, latDiff, lonDiff, latStep, lonStep)
%INTERPOLATETECMAP Interpolate between four TEC values.
tec = ( tecMap(1,1)*latDiff(2)*lonDiff(2) + ...
        tecMap(2,1)*latDiff(1)*lonDiff(2) + ...
        tecMap(1,2)*latDiff(2)*lonDiff(1) + ...
        tecMap(2,2)*latDiff(1)*lonDiff(1) ) / abs(latStep*lonStep);

end