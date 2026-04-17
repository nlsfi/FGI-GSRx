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
classdef rinex3ObsTypeNum < handle
% RINEX3OBSTYPENUM object type to store observation types for a satellite system.
%
% properties:
%   satellite:rinex3SatId
%       satellite whose observation types are specified.
%       length(satellite)=1 at all times. setting otherwise
%       will raise an error.
%   noObs:double
%       number of observations.
%   obsCodes:rinex3ObsId
%       an array of observation types associated with the satellite.
% methods:
%   appendObsTypeNum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        satellite       % rinex3SatId
        noObs          % double
        obsCodes       % rinex3ObsId
    end

    methods
        function obj=rinex3ObsTypeNum(s,n,oc)
        % RINEX3OBSTYPENUM
        if nargin==3
            obj.satellite=s;
            obj.noObs=n;
            obj.obsCodes=oc;
        else
            obj.satellite=rinex3SatId();
            obj.noObs=-1;
            obj.obsCodes=[rinex3ObsId()];
        end
        end
        %end of function rinex3ObsTypeNum


        function appendObsTypes(obj,i)
        % RINEX3OBSTYPENUM.APPENDOBSTYPES appends obsCodes of i 
        % onto obsTypes of obj, (and similarly noObs will be
        % the sum of two noObs) if both belong to the same satellite
        % system.
        % i:rinex3ObsTypeNum

        if ~isa(i,'rinex3ObsTypeNum')
            error('rinex3ObsTypeNum:incorrectType',...
                'input must be of type rinex3ObsTypeNum, but not %s',class(i))
        end
        % TODO what if obsCodes are repeatative?
        % is that a bug?
        if obj.satellite.system==i.satellite.system
            obj.obsCodes=[obj.obsCodes,i.obsCodes];
            obj.noObs=obj.noObs+i.noObs;
        else
            error('rinex3ObsTypeNum:badSystem',...
                'observation codes must belong to the same satellite system.')
        end
        end
        % end of function append


        function set.satellite(obj,i)
        if ~isa(i,'rinex3SatId')
            error('rinex3ObsTypeNum:incorrectType',...
                'input must be of rinex3SatId type, but not %s',class(i))
        else
            obj.satellite=i;
            %TODO length check
        end
        end
        %end of function set.satellite(obj,i)


        function set.noObs(obj,i)
        if ~isa(i,'double')
            error('rinex3ObsTypeNum:incorrectType',...
                'input must be of double type, but not %s',class(i))
        else
            obj.noObs=i;
        end
        end
        %end of function set.noObs(obj,i)


        function set.obsCodes(obj,i)
        if ~isa(i,'rinex3ObsId')
            error('rinex3ObsTypeNum:incorrectType',...
                'input must be of rinex3ObsId type, but not %s',class(i))
        else
            obj.obsCodes=i;
        end
        end
        % end of function set.obsCodes(obj,i)

    end
    %end of methods
end
