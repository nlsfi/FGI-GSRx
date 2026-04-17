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
classdef rinex3ObsData < rinex3commonData
    % RINEX3OBSDATA data type to store a data block of a rinex 3.04 file,
    % data block referring to observables, observable types, time, etc in
    % defined in accordance to a corresponding rinex 3.04 header which is
    % captured by a receiver at a given epoch.
    %
    % properties:
    %   epochTime:datetime
    %   epochFlag:double
    %   clckOffset:double
    %
    % methods:
    %   char=writeEpochTime
    %   cmps
    %   setObs
    %   bool=isValid
    %   sortObs
    %   sortObsInner 
    properties
        epochFlag = NaN;
        epochTime = NaT;
        clckOffset = NaN;


    end

    methods
        function clear(obj)
            obj.epochTime = NaT;
            obj.clckOffset = NaN;
            obj.epochFlag = NaN;
        end

        function set.epochFlag(obj, i)
            if ~isa(i, 'double')
                error('%s:incorrectType', class(obj), ...
                      'epochFlag must be double, not %s', class(i))
            else
                obj.epochFlag = i;
            end
        end

        function set.epochTime(obj, i)
            if ~isdatetime(i)
                error('%s:incorrectType', class(obj), ...
                      'epochTime must be datetime, not %s', class(i))
            elseif numel(i) > 1
                error('%s:invalidInput', class(obj), ...
                      'epochTime must be scalar')
            else
                obj.epochTime = i;
            end
        end

        function set.clckOffset(obj, i)
            if ~isa(i, 'double')
                error('%s:incorrectType', class(obj), ...
                      'clckOffset must be double, not %s', class(i))
            else
                obj.clckOffset = i;
            end
        end
    
        function obj=rinex3ObsData()
        % TODO
        if nargin>0
            return
        end
        end

        parse(obj,fileId,r3oh)

        % write the data record
        cmps(obj,fileId,r3oh)
        
        % set obsevations from meas 
        setObs(obj,meas,r3oh)
        
        % validity check
        b=isValid(obj,r3oh)


        function parseEpochTime(obj,line)
        % PARSEEPOCHTIME
        % TODO change epochTime from containers.Map to datetime
        % deal with special event record times, write out Nat
        % if time is not available.
        [t1,n1Read]=sscanf(line(2:18),'%u');
        [t2,n2Read]=sscanf(line(19:29),'%f');
        if n1Read~=5||n2Read~=1
            error('invalid time foramt.')
        end
        obj.epochTime=datetime(t1(1),t1(2),t1(3),t1(4),t1(5),t2);

        end
        % end of function parseEpochTime


        function s=writeEpochTime(obj)
        % WRITEEPOCHTIME
        % s:char array

        fs={' %-4u'};
        fs=strcat(fs,{repmat(' %02u',1,4)});
        fs=strcat(fs,{'%11.7f'});
        
        s=sprintf(fs{1},obj.epochTime.Year,obj.epochTime.Month,...
                  obj.epochTime.Day,obj.epochTime.Hour,...
                  obj.epochTime.Minute,obj.epochTime.Second);
        end
    end
    % end of methods block

    methods (Static=true)
        
    end
    % end of methods block

end
