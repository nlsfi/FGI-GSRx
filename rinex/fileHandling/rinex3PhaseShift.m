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
classdef rinex3PhaseShift < handle
    % RINEX3PHASESHIFT
    % TODO
    properties
        satellites
        obsCode
        correction  %[cycles]
    end
    
    methods
        function obj=rinex3PhaseShift(sats,oc,c)
        if nargin==3
            obj.satellites=sats;
            obj.obsCode=oc;
            obj.correction=c;
        else
            obj.satellites=[rinex3SatId()];
            obj.obsCode=rinex3ObsId();
            obj.correction=NaN;
        end
        end
        % end of function obj=rinex3PhaseShift

        %======================        
        function b=isValid(obj)
        % ISVALID
        b=true;
        if any([obj.satellites.system]==satSysId.systemUnknown)
            b=false;
            error('rinex3PhaseShift:invalid',...
                'satellite system can not be satSysId.systemUnknown.')
            return
        end
        
        if ~all([obj.satellites.system]==obj.satellites(1).system)
            b=false;
            error('rinex3PhaseShift:invalid',...
                'all satellites must belong to the same system.')
            return
        end
        % If obj.satellites(1).p is (-1), 
        % it means all the satellites in that system are treated the same way,
        % otherwise in case only select few of the satellites are specified,
        % then obj.satellites(i).p can not be (-1),
        % (i: being [1:length(satellites)])
        if length(obj.satellites)>1
            if any([obj.satellites.p]==-1);
                b=false;
                error('rinex3PhaseShift:invalid',...
                    'an individual satellite.p can not be (-1)')
                return
            end
        end

        % by definition, this is defined only for phase
        % observables.
        [obsValid,whValid]=ismember(obj.obsCode.observationType,...
            [obsType.phase,obsType.unknown]);
        if ~obsValid
            b=false;
            error('rinex3PhaseShift:invalid',...
                'obsCode can only contain obsType.phase or obsType.unknown')
            return
        elseif whValid==2
            % .satellites must be scalar with p=-1
            % correction=NaN
%             warning('rinex3PhaseShift:invalid',...
%                 'obsCode is obsType.unknown.')
            if (length(obj.satellites)>1 || ~isnan(obj.correction))
                b=false;
                error('rinex3PhaseShift:invalid',...
                    ['the only valid combination for properties',...
                    ' of an object of type rinex3PhaseShift with',...
                    ' obsType.unknown is',...
                    ' (obsType.unknown,satellites.p=-1,correction=NaN)'])
                return

            end
        end

        end
        % end of function isValid
        
        %=============================
        function set.satellites(obj,i)
        if ~isa(i,'rinex3SatId')
            error('rinex3PhaseShift:incorrectType',...
                'input must be of rinex3SatId type, but not %s',class(i))
        else
            obj.satellites=i;
        end
        end
        %end of function set.satellites(obj,i)


        function set.obsCode(obj,i)
        if ~isa(i,'rinex3ObsId')
            error('rinex3PhaseShift:incorrectType',...
                'input must be of rinex3ObsId type, but not %s',class(i))
        elseif length(i)>1
            error('rinex3PhaseShift:incorrectLength',...
                'input must be of length 1, but not of length %u',length(i))
        else
            obj.obsCode=i;
        end
        end
        % end of function set.obsCode(obj,i)


        function set.correction(obj,i)
        if ~isa(i,'double')
            error('rinex3PhaseShift:incorrectType',...
                'input must be of double type, but not %s',class(i))
        elseif length(i)>1
            error('rinex3PhaseShift:incorrectLength',...
                'input must be of length 1, but not of length %u',length(i))
        else
            obj.correction=i;
        end
        end
        % end of function set.correction
    end
    % end of methods block
end
