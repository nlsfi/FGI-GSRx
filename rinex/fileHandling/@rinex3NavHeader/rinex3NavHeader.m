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
classdef rinex3NavHeader < rinex3CommonHeader
% RINEX3NAVHEADER is a data type to store rinex3.04 header file.
%
% properties:
%   version:double
%   fileType:double
%   fileSatSys:rinex3SatId
%   fileProgram:char
%   fileAgency:char
%   date:char
%   commentList:cell
%   ionoCorr:struct
%   timesysCorr:struct
%   leapSecs:char
%
%
% methods:
%   bool=isValid
%   cmps
%
% | Header Field            | Req | Variables
% |-------------------------|-----|---------
% | RINEX VERSION / TYPE    |  y  | version,fileType,fileSatSys
% | PGM / RUN BY / DATE     |  y  | fileProgram,fileAgency,date
% | COMMENT                 |  n  | commentList
% | IONOSPHERIC CORR        |  n  | corrType, params, timeMark, svId
% | TIME SYSTEM CORR        |  n  | timeType, a0, a1, weekS, 
% |                         |     | weekNum, source, utcId
% | LEAP SECONDS            |  n  | leapSecs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (Constant=true,Hidden=true)
        hlVer='RINEX VERSION / TYPE';
        hlRunby='PGM / RUN BY / DATE';
        hlComment='COMMENT';
        hlIonoCorr='IONOSPHERIC CORR';
        hlTimesysCorr='TIME SYSTEM CORR';
        hlLeapSec='LEAP SECONDS';
        hlEoh='END OF HEADER';
    end
    
    properties (Access=protected)
        % The optional header records
        % TODO dcbs, scale factor,pcvs,
        validLeapSecs=false;
        validIonoCorr=false;
        validTimesysCorr=false;
    end
    
    properties
        
        interval=seconds(NaN);
        timeFirstObs=NaT;
        lsf=NaN;
        wnLsf=NaN;
        dn=NaN;
        leapSecs=NaN;
        tsysid='';
        ionoCorr=NaN;
        timesysCorr=NaN;
    end

    methods

        function obj=rinex3NavHeader(~)
            % default contructor
            %obj.clear()
            if nargin>0
                return
            end
        end
        % end of function obj=rinex3ObsId

        %============================
        % compose a rinex file header
        cmps(obj,fileId)
        % check if the header contains a valid set of information
        b=isValid(obj)
        % parse a ASCII rinex file
        parse(obj,fileId)

        %==================
        function clear(obj)
            % CLEAR set the properties to default ones.
            %
            obj.interval=seconds(NaN);
            obj.timeFirstObs=NaT;
            obj.lsf=NaN;
            obj.wnLsf=NaN;
            obj.dn=NaN;
            obj.tsysid='';
            obj.leapSecs=NaN;
            obj.ionoCorr=NaN;
            obj.timesysCorr=NaN;
            obj.validCommentList=false;      
        end

        %===========================
        function set.ionoCorr(obj,i)
            %%%TODO
            obj.ionoCorr = i;
            obj.validIonoCorr = true;
        end
        % end of function set.ionoCorr

        %===========================        
        function set.timesysCorr(obj,i)
            %%%TODO
            obj.timesysCorr = i;
            obj.validTimesysCorr = true;
        end
        % end of function set.timesysCorr
        
        %===========================
        function set.leapSecs(obj,i)
            if ~isa(i,'double')
                error('rinex3ObsHeader:incorrectType',...
                    'input must be of double type, but not %s',class(i))
            else
                obj.leapSecs=i;    
                obj.validLeapSecs=true;
            end
        end
        % end of function set.leapSecs

        %==========================
        function set.wnLsf(obj,i)
            if ~isa(i,'double')
                error('rinex3ObsHeader:incorrectType',...
                    'input must be of double type, but not %s',class(i))
            else
                obj.wnLsf=i;
            end
        end
        % end of function set.wnLsf

        %==========================
        function set.lsf(obj,i)
            if ~isa(i,'double') && isempty(i)
                error('rinex3ObsHeader:incorrectType',...
                    'input must be of double type, but not %s',class(i))
            else
                obj.lsf=i;
            end
        end
        % end of function set.lsf


        %==========================
        function set.tsysid(obj,i)
            if ~isa(i,'char')
                error('rinex3ObsHeader:incorrectType',...
                    'input must be of char type, but not %s',class(i))
            else
                obj.tsysid=i;
            end
        end
        % end of function set.tsysid


        %==========================
        function set.dn(obj,i)
            if ~isa(i,'double')
                error('rinex3ObsHeader:incorrectType',...
                    'input must be of double type, but not %s',class(i))
            else
                obj.dn=i;
            end
        end
        % end of function set.dn

    end
    % end of methods

    methods(Static=true)
    %========
    
    end
    % end of methods

end
