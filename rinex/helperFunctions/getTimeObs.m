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
function [tfo,tso,tlo,timeSystem]=getTimeObs(obsData, settings)
% GETTIMEOBS compute time of first, second and last observation captured by the FGI-GSRx3. 
% It looks at the tow and week number of the first system in obsData 
% structure.
%
% Inputs:
%   obsData:struct            - newObsData from generateRinex function
%
% Outputs:
%   tfo:containers.Map         - time of first observation
%   tso:containers.Map         - time of second observation
%   tlo:containers.Map         - time of last observation
%   timeSystem:rinex3SatId    - satellite system wrt which tfo and tlo are defined
%
% NB. tfo and tlo are defined wrt the time system
% defined within as is required by Rinex file format specification 
% document one possible point to note: RINEX 3.04.IGS.RTCM.doc Table 22
% for more info look at https://navians.org/issues/328#note-2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
satSystems=fieldnames(obsData);

% TODO as of now, none of us knows what navData{c}.receiverTow
% is. More precisely we don't know which time system it belongs to.
% For the moment, I assume its just the first one,
% till somebody figures this out. Obviously this is wrong.
obsDataSingleSys=getfield(obsData,satSystems{1});

wN=obsDataSingleSys.channel(1).week;
tow1=obsDataSingleSys.receiverTow(1);
tow2=obsDataSingleSys.receiverTow(2);
towEnd=obsDataSingleSys.receiverTow(end);
timeSystem=inferSatSystem(satSystems(1));

zeroTime=getZeroTime(timeSystem, settings.rnx.gpsRollovers); % zerotime includes GPS week number rollovers.

tfo=seconds(tow1)+days(wN*7)+zeroTime;
tso=seconds(tow2)+days(wN*7)+zeroTime;

tlo=seconds(towEnd)+days(wN*7)+zeroTime;
end