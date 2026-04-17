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
classdef (Abstract) rinex3CommonHeader < handle
% RINEX3HEADERBASE Shared properties and setters for RINEX file headers.
% Both rinex3ObsHeader and rinex3NavHeader inherit this.
%
% properties:
%   version:double
%   fileType:double
%   fileSatSys:rinex3SatId
%   fileProgram:char
%   fileAgency:char
%   date:char
%   commentList:cell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        version = 0.0
        fileType = ''
        fileSatSys = rinex3SatId()
        fileProgram = ''
        fileAgency = ''
        date = ''
        commentList = {}
        sysObsNoTypes=[rinex3ObsTypeNum()]

    end

    properties (Access=protected)
        validCommentList = false
    end

    methods
        function clear(obj)
            obj.version = 0.0;
            obj.fileType = '';
            obj.fileSatSys = rinex3SatId();
            obj.fileProgram = '';
            obj.fileAgency = '';
            obj.date = '';
            obj.commentList = {};
            obj.sysObsNoTypes=[rinex3ObsTypeNum()];
        end
        %==================
        function set.version(obj, i)
            if ~isa(i, 'double')
                error('%s:incorrectType', class(obj), ...
                    'version must be double, not %s', class(i))
            end
            obj.version = i;
        end

        %==================
        function set.fileType(obj, i)
            if ~ischar(i)
                error('%s:incorrectType', class(obj), ...
                    'fileType must be char, not %s', class(i))
            elseif length(i) ~= 1
                error('%s:badInput', class(obj), ...
                    'fileType must be exactly one character')
            end
            obj.fileType = i;
        end

        %==================
        function set.fileSatSys(obj, i)
            if ~isa(i, 'rinex3SatId')
                error('%s:incorrectType', class(obj), ...
                    'fileSatSys must be rinex3SatId, not %s', class(i))
            elseif length(i) > 1
                error('%s:badInput', class(obj), ...
                    'fileSatSys must be scalar')
            end
            obj.fileSatSys = i;
        end

        %==================
        function set.fileProgram(obj, i)
            if ~ischar(i)
                error('%s:incorrectType', class(obj), ...
                    'fileProgram must be char, not %s', class(i))
            elseif length(i) > 20
                error('%s:badInput', class(obj), ...
                    'fileProgram must be ≤20 chars')
            end
            obj.fileProgram = i;
        end

        %==================
        function set.fileAgency(obj, i)
            if ~ischar(i)
                error('%s:incorrectType', class(obj), ...
                    'fileAgency must be char, not %s', class(i))
            elseif length(i) > 20
                error('%s:badInput', class(obj), ...
                    'fileAgency must be ≤20 chars')
            end
            obj.fileAgency = i;
        end

        %==================
        function set.date(obj, i)
            if ~ischar(i)
                error('%s:incorrectType', class(obj), ...
                    'date must be char, not %s', class(i))
            elseif length(i) > 20
                error('%s:badInput', class(obj), ...
                    'date must be ≤20 chars')
            end
            obj.date = i;
        end

        %==================
        function set.commentList(obj, i)
            if ~iscell(i)
                error('%s:incorrectType', class(obj), ...
                    'commentList must be a cell array')
            end
            for c = 1:numel(i)
                if ~ischar(i{c})
                    error('%s:incorrectType', class(obj), ...
                        'each comment must be char')
                elseif length(i{c}) > 60
                    error('%s:badInput', class(obj), ...
                        'each comment ≤60 chars')
                end
            end
            obj.commentList = i;
            obj.validCommentList = true;
        end

        %================
        function set.sysObsNoTypes(obj,i)
        if ~isa(i,'rinex3ObsTypeNum')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of rinex3ObsType, but not %s',class(i))
        else
            obj.sysObsNoTypes=i;
        end
        end
        
        %================
        function dispSysObsNoTypes(obj)
        % DISPSYSOBSNOTYPES
        % display obj.sysObsNoTypes
        % on the command window.
        line={sprintf(['| satellite system |',' number of observations |',...
                   ' observation types |\n'])};
        fprintf(line{1});

        nl=length(obj.sysObsNoTypes);
        for ii=1:nl
            sysDescr=obj.sysObsNoTypes(ii).satellite.as3letter();
            nrObs=obj.sysObsNoTypes(ii).noObs;
            line={'| '};
            line=strcat(line,{sprintf('%3s',sysDescr)});
            line=strcat(line,{' |'});
            line=strcat(line,{sprintf(' %02u',nrObs)});
            line=strcat(line, {' |'});
            for jj=1:nrObs
                obsType=obj.sysObsNoTypes(ii).obsCodes(jj);
                line=strcat(line,{sprintf(' %3s,',obsType.as3letter())});
            end
            line=strcat(line,{' |\n'});
            fprintf(line{1});
        end
        end
    end
end
