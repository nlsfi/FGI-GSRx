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
function [gpsTime, gpsWeek] = utcToGpsTime(const, year,month,day,hour,min,sec,leap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Converts utc time to gps time
%
% Inputs:
%   const       - Constants
%   year        - UTC year
%   month       - UTC month
%   day         - UTC day
%   hour        - UTC hour
%   min         - UTC min
%   sec         - UTC sec
%   leap        - UTC leap seconds
% 
% Output: 
%   gpsTime     - GPS time of week in seconds
%   gpsWeek     - GPS week number
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TBA. Check variable names

% Tabel with days in month
TabYearMonth = [0 31 59 90 120 151 181 212 243 273 304 334 365;
            0 31 60 91 121 152 182 213 244 274 305 335 366];

% Constants        
SECONDS_IN_MINUTE = const.SECONDS_IN_MINUTE;
SECONDS_IN_HOUR = const.SECONDS_IN_HOUR;
SECONDS_IN_DAY = const.SECONDS_IN_DAY;
SECONDS_IN_WEEK = const.SECONDS_IN_WEEK;

% Temporary variables
SecWithinDay = 3600 * hour + 60 * min + sec;
yero = year - 1980;
DaysOfLeap = floor(yero/4 + 1);

if (mod(yero,4)==0 && month <= 2)
    DaysOfLeap = DaysOfLeap - 1;
end

dero = yero*365 + TabYearMonth(1,month) + day + DaysOfLeap - 6;

iWeek = floor(dero / 7);
tow = mod(dero,7) * SECONDS_IN_DAY + hour*SECONDS_IN_HOUR +...
        min * SECONDS_IN_MINUTE + sec;% + pUTC->Time.dwSubSec / 1.0e9;

while (tow<0.0)
    iWeek = iWeek - 1;
    tow = tow + SECONDS_IN_WEEK;
end

while (tow>=SECONDS_IN_WEEK)
    iWeek = iWeek + 1;
    tow = tow - SECONDS_IN_WEEK;
end

tow = tow + leap;

if (tow > SECONDS_IN_WEEK)
    tow = tow - SECONDS_IN_WEEK;
    iWeek = iWeek + 1;
else
    if (tow < 0.0)
        tow = tow + SECONDS_IN_WEEK;
        iWeek = iWeek - 1;
    end
end

gpsTime = tow;
gpsWeek = iWeek;




