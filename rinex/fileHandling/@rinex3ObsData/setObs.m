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
function setObs(obj,meas,r3oh)
% RINEX3OBSDATA.SETOBS
% setObs(meas,r3oh) sorts meas according to the r3oh.sysObsNoTypes
% and sets obj.observations.
% meas:cell
%   meas={A1,A2} where
%       A1={a1,a2,a3,a4}
%       a1:satSysId
%           indicates the time system
%       a2:datetime 
%           epoch time
%       a3:double
%           epoch flag (acceptable range:[0:6])
%       a4:double
%           clock offset (could be NaN)
%
%       A2={m1,m2,m3,...} where mi={A,B,D,E}
%           A:rinex3SatId
%               satellite identifier    
%           B:rinex3ObsId
%               observation type
%           D:double
%               measurement of type B of satellite A
%           
%
% r3oh:rinex3ObsHeader
%   header
% the only restriction on meas is that obviously the contents must belong
% the epoch as indicated by A1, otherwise setObs internally sorts the A2
% according to the contents of r3oh.sysObsNoTypes. Pay attention that 
% length(obj.observations) is dictated by the number of satellite systems
% as defined within r3oh.sysObsNoTypes; if by any chance meas contains
% measurements belonging to satellite systems which are not defined in
% r3oh.sysObsNoTypes, those measurements will be discarded. On the
% other hand if a measurement is missing (Not a Nan, but missing cell)
% from a satellite, setObs will place a cell ({A,B,D}) with D=NaN.
% Therefore number of individual cells in obj.observations are not necessarily
% equal to length(A2)

if ~r3oh.isValid()
    error('rinex3ObsData:invalidRinex3ObsHeader',...
        'rinex3ObsHeader instance is not valid.')
end


obj.epochTime=meas{1}{2};
obj.epochFlag=meas{1}{3};
obj.clckOffset=meas{1}{4};

ssm=obj.sortObs(meas{2},r3oh);
obj.observations=ssm;

% caclulate number of satellites
numSvs=0;
for i=1:length(ssm)
    numSvs=numSvs+length(ssm{i})/r3oh.sysObsNoTypes(i).noObs;
end
obj.numSvs=numSvs;
end
