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
function ionexTables = parseIonex( filename )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Parse an IONEX file into a struct which contains data tables for all
%  time instances, corresponding time instances, latitudes, longitudes,
%  and heights.
% 
% Input:
%   filename      -   Filename of ionex file
%
% Output:
%   ionexTables   - Table with TEC values 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fid = fopen(filename);
[NTows, baseRadius] = skipHeader(fid);

tows = zeros(NTows,1);

[tows(1),firstMap,lats,lons,height] = parseOneTecMap(fid,1);

tecMaps = zeros(size(firstMap,1),size(firstMap,2),NTows);
tecMaps(:,:,1) = firstMap;

for i = 2:NTows
  [tows(i),tecMaps(:,:,i),newLat,newLons,newHeight] = parseOneTecMap(fid,i);
  assert(all(newLat == lats) && all(newLons == lons) && ...
         all(newHeight == height))
end

ionexTables = struct;

ionexTables.height = height * 1e3; % The height should be in km
ionexTables.latStep = lats(2) - lats(1);
ionexTables.lonStep = lons(2) - lons(1);
ionexTables.timeStep = tows(2) - tows(1);
ionexTables.longitudes = lons;
ionexTables.latitudes = lats;
ionexTables.tows = tows;
ionexTables.maps = tecMaps;
ionexTables.baseRadius = baseRadius;
fclose(fid);
end


function [Nmaps, baseRadius] = skipHeader(fid)
%SKIPHEADER Simply skip all the lines which are part of the header.
line = fgetl( fid );
  while ischar( line )
      if ~isempty( regexp(line, 'END OF HEADER','ONCE') )
          return;
      end
      if ~isempty( strfind( line(61:end), '# OF MAPS IN FILE' ) )
          Nmaps = str2double( line(1:60) );
      end
      
      if ~isempty( strfind( line(61:end), 'BASE RADIUS' ) )
          baseRadius = str2double( line(1:60) );
      end
      
      line = fgetl( fid );
  end
end


function [tow,map, lats, lons, height] = parseOneTecMap(fid, mapNr)
%PARSEONETECMAP Parse the lines that correponds TEC map of one epoch.

% Allocate memory for the map
map = zeros(71,73);
lats = zeros(1,71);

% First line should have the map number
assert( ~isempty( regexp( fgetl(fid), [num2str(mapNr) ...
                                       ' +START OF TEC MAP'], 'ONCE' ) ))
% Second line should have the time
timePtrn = repmat('\d+ +',1,6);
tow = time2tow( regexp( fgetl(fid) , timePtrn, 'match','once') );
% Third line should have the latitude, longitude, and height
for i = 1:71
    [lats(i), lons, height] = parseLatLonLine( fgetl(fid) );
    if i > 1
      assert(all(lons == previousLons) && all(height == previousHeight));
    end
    % Then the next five lines should have 73 tec numbers
    for j=1:4
      map(i, 1+(j-1)*16:j*16) = str2num( fgetl(fid) );
    end
    map(i, 1+4*16:end) = str2num( fgetl(fid) );
    % Save old lons and height for comparison
    previousLons = lons;
    previousHeight = height;
end

assert( ~isempty( regexp( fgetl(fid), [num2str(mapNr) ...
                                       ' +END OF TEC MAP' ], 'ONCE') ) )
end


function [lat,lons,height] = parseLatLonLine(line)
%PARSELATLONLINE Parse latitude and longitude values from a line.
latLonPtrn = '-*\d+.\d+-180.0 180.0 +5.0 \d+.0';
latlon = regexp( line , latLonPtrn, 'match','once');
latlon = strrep(latlon,'-',' -');
split = str2num(latlon);
lat = split(1);
height = split(end);
lons = -180:5:180;
end


function [tow, week, dateNum] = time2tow( timestr )
%TIME2TOW Convert a Rinex epoch to Matlab datenum and TOW
%   Compute TOW by subtracting the time 1980-01-01 00:00:00 and take the
%   elapsed seconds from the beginning of a week.
%
%   Warning: using datenum to convert the time string to days has the
%   precision of a millisecond. Hence, if the string has more precision,
%   this will be ignored.

% Check whether the year is in yy or yyyy format
year = regexp(timestr,'\d+','match','ONCE');

if length(year) == 2
    dateNum = datenum(timestr, 'yy mm dd HH MM SS');
elseif length(year) == 4
    dateNum = datenum(timestr, 'yyyy mm dd HH MM SS');
else
    error('Invalid year token in time string')
end

t0 = datenum('1980-01-06','yyyy-mm-dd');
tow = mod( dateNum - t0 , 7 ) * (24 * 60 * 60); 
% Round TOW to the closest millisecond
tow = round(tow*1000)/1000;

week = floor( ( dateNum - t0 ) / 7 );
end