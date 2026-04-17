%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2015-2026 Finnish Geospatial Research Institute FGI, National
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
function zeroTime = getZeroTime(timeSystem, gpsRollovers)
% GETZEROTIME returns the zero time for a given satellite system, accounting for GPS week number rollovers if applicable.
% 
% Inputs:
% timeSystem:rinex3SatId    - satellite system for which to compute zero time
% gpsRollovers:integer      - number of GPS week number rollovers to account for. 
%                             (other systems rollovers need to be implemented)
% Outputs:
% zeroTime:datetime         - the computed zero time for the given satellite system
    switch timeSystem.system
        case satSysId.systemGalileo
            zeroTime = datetime('1999-08-22 00:00:00');
            
        case satSysId.systemGPS
            zeroTime = datetime('1980-01-06 00:00:00');
            if gpsRollovers > 0
                zeroTime = zeroTime + days(7*1024*gpsRollovers); % account for GPS week number rollovers
            end
        case satSysId.systemBDS
            zeroTime = datetime('2006-01-01 00:00:00');
        otherwise
            error('Unsupported satellite system. Alter the implementation.');
    end

end