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
function b=isValid(obj)
% rinex3ObsHeader.ISVALID
% isValid() returns true if header conatains all
% the mandatory information. This function is realized for rinex3.04 only.
% NB. because of ambiguity in rinex3.04 document,
% antPositionXyz is not considered mandatory in this function.

b=true;

% TODO improve the warning messages.
% replace them with errors, maybe try to catch them.
if obj.version ~= 3.04
    b=false;
    warning('rinex3ObsHeader:invalid',...
        'version of rinex observation must be 3.04')
    return
end

if ~ismember(obj.fileType,{'O','o'})
    b=false;
    warning('rinex3ObsHeader:invalid',...
        'only observation file type is allowed.')
    return;
end

if obj.fileSatSys.system==satSysId.systemUnknown
    b=false;
    warning('rinex3ObsHeader:invalid',...
        'fileSatSystem must be known.')
    return;
end

if any(isnan(cell2mat(values(obj.antDelHen))))
    b=false;
    warning('rinex3ObsHeader:invalid',...
        'antDelHen is NaN.')
    return;
end

% obj.sysObsNoTypes
% can not have duplicate satellite systems
% can not be systemMixed nor systemUnknown
satellites=[obj.sysObsNoTypes.satellite];
systems=[satellites.system];
if length(unique(systems))~=length(systems)
    b=false;
    warning('rinex3ObsHeader:invalid',...
        'sysObsNoTypes must not have duplicate satellite systems.')
    return
end
forbiddenSystems=ismember(systems,...
    [satSysId.systemUnknown,satSysId.systemMixed]);
if any(forbiddenSystems)
    error('rinex3ObsHeader:invalid',...
        ['sysObsNoTypes can not be satSysId.systemUnknown',...
        ' nor satSysId.systemMixed'])
end

if ismember(obj.timeSystem.system,...
        [satSysId.systemMixed,satSysId.systemUnknown])
        error('rinex3ObsHeader:invalid',...
            'timeSystem can not be %s',char(timeSystem.system))
end
if isnat(obj.timeFirstObs)
    error('rinex3ObsHeader:invalid',...
        'timeFirstObs is NaT.')
end

for c=1:length(obj.sysPhaseShift)
    if ~obj.sysPhaseShift(c).isValid()
        b=false;
        error('rinex3ObsHeader:invalid',...
            'sysPhaseShift(%u) is not valid.',c)
        return
    end
end

end
