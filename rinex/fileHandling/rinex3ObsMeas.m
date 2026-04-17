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
classdef rinex3ObsMeas < handle
% RINEX3OBSMEAS data object to store measurements of the observables.
%
% properties:
%   satellite:rinex3SatId
%       satellite whose measurements/observables are dealt with.
%       length(satellite)=1, setting otherwise will raise an error.
%   obsCodes:rinex3ObsId
%       observation types associated with the satellite. This is
%       an array of rinex3ObsId.
%   values:double
%       array of measurements. These could also be NaN.
% methods:
%   bool=isValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        satellite           % rinex3SatId
        obsCodes           % rinex3ObsId
        values              % double
    end

    methods

        function obj=rinex3ObsMeas(s,oc,v)
        if nargin==3
            obj.satellite=s;
            obj.obsCodes=oc;
            obj.values=v;
        else
            obj.satellite=rinex3SatId();
            obj.obsCodes=[rinex3ObsId()];
            obj.values=[NaN];
        end
        end
        % end of rinex3ObsMeas


        function b=isValid(obj)
        % RINEX3OBSID.ISVALID
        % returns false if 
        % either of the p or system in satellite(p,system) is -1/unknown
        % number of values do not match the number of obsCodes
        % otherwise returns true.
        %
        % NB. any of the values could be NaN, and NaN in the context of
        % rinex 3.xx files means missing.

        b=true;
        [bs,bp]=obj.satellite.isValid();
        if (~bs || ~bp)
            b=false;
            return
        end

        if length(obj.obsCodes)~=length(obj.values)
            b=false;
            return
        end

        for c=1:length(obj.obsCodes)
            if ~obj.obsCodes(c).isValid()
                b=false;
                return
            end
        end
        end
        % end of function isValid


        function set.satellite(obj,i)
        if ~isa(i,'rinex3SatId')
            error('rinex3ObsMeas:incorrectType',...
                'input must be of rinex3SatId type, but not %s',class(i))
        elseif length(i)>1
            error('rinex3ObsMeas:incorrectLength',...
                'inut must be of length 1, but not of length %u',length(i))
        else
            obj.satellite=i;
        end
        end
        % end of function set.satellite


        function set.obsCodes(obj,i)
        if ~isa(i,'rinex3ObsId')
            error('rinex3ObsMeas:incorrectType',...
                'input must be of type rinex3ObsId but not %s',class(i))
        else
            obj.obsCodes=i;
        end
        end
        % end of function set.obsCodes


        function set.values(obj,i)
        if ~isa(i,'double')
            error('rinex3ObsMeas:incorrectType',...
                'input must be of type double but not %s',class(i))
        else
            obj.values=i;
        end
        end
        % end of function set.values

    end
    % end of methods

end
