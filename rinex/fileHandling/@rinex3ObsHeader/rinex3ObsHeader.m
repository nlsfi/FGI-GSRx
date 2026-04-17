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
classdef rinex3ObsHeader < rinex3CommonHeader
% RINEX3OBSHEADER Data type to store rinex3.04 header file.
%
% properties:
%   markerName:char
%   markerNumber:char
%   markerType:char
%   observer:char
%   agency:char
%   rxNumber:char
%   rxType:char
%   rxVersion:char
%   antNumber:char
%   antType:char
%   antPositionXyz:containers.Map
%   antDelHen:containers.Map
%   antDelXyz:containers.Map
%   antSatSys:rinex3SatId
%   antObsCode:rinex3ObsId
%   antPhaseCntrIjk:containers.Map
%   antBsightXyz:containers.Map
%   antZeroDirAzi:double
%   antZeroDirXyz:containers.Map
%   cntrMassXyz:containers.Map
%   sigStrengthUnit:char
%   interval:duration
%   timeSystem:rinex3SatId
%   timeFirstObs:datetime
%   timeLastObs:datetime
%   clckOffsetAppl:bool
%   infoDcbs:char
%   infoPcvs:char
%   sysScaleFactor:double
%   sysPhaseShift:rinex3PhaseShift
%   glonassSlotFreq*:char
%   glonassCodePhaseBias*:char
%   leapSecs:char
%   numSvs:double
%   numObsPerSv*:char
%
%   *: means its not implemented yet,
%   so subject to change in the future
%
%
% methods:
%   bool=isValid
%   cmps
%   parse
%
% | Header Field            | Req | Variables
% |-------------------------|-----|---------
% | MARKER NAME             |  y  | markerName
% | MARKER NUMBER           |  n  | markerNumber
% | MARKER TYPE             |  y  | markerType
% | OBSERVER / AGENCY       |  y  | observer,agency
% | REC # / TYPE / VERS     |  y  | rxNumber,rxType,rxVersion
% | ANT # / TYPE            |  y  | antNumber,antType
% | APPROX POSITION XYZ     |  y  | antPositionXyz
% | ANTENNA: DELTA H/E/N    |  y  | antDelHen
% | ANTENNA: DELTA X/Y/Z    |  n  | antDelXyz
% | ANTENNA: PHASECENTER    |  n  | antSatSys, antObsCode,
% |                         |  n  | antPhaseCntrIjk
% | ANTENNA: B.SIGHT XYZ    |  n  | antBsightXyz
% | ANTENNA: ZERODIR AZI    |  n  | antZeroDirAzi
% | ANTENNA: ZERODIR XYZ    |  n  | antZeroDirXyz
% | CENTER OF MASS: XYZ     |  n  | cntrMassXyz
% | SYS / # OBS / TYPES     |  y  | sysObsNoTypes
% | SIGNAL STRENGTH UNIT    |  n  | sigStrengthUnit
% | INTERVAL                |  n  | interval
% | TIME OF FIRST OBS       |  y  | timeSystem,timeFirstObs
% | TIME oF LAST OBS        |  n  | timeLastObs
% | RCV CLOCK OFFS APPL     |  n  | clckOffsetAppl
% | SYS / DCBS APPLIED      |  n  | infoDcbs
% | SYS / PCVS APPLIED      |  n  | infoPcvs
% | SYS / SCALE FACTOR      |  n  | sysScaleFactor
% | SYS / PHASE SHIFT       |  y  | sysPhaseShift
% | GLONASS SLOT / FREQ #   |  y  | glonassSlotFreq
% | GLONASS COD/PHS/BIS     |  y  | glonassCodePhaseBias
% | LEAP SECONDS            |  n  | leapSecs
% | # OF SATELLITES         |  n  | numSvs
% | PRN / # OF OBS          |  n  | numObsPerSv
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties (Constant=true,Hidden=true)
        hlVer='RINEX VERSION / TYPE';
        hlRunby='PGM / RUN BY / DATE';
        hlComment='COMMENT';
        hlMarkerName='MARKER NAME';
        hlMarkerNumber='MARKER NUMBER';
        hlMarkerType='MARKER TYPE';
        hlObs='OBSERVER / AGENCY';
        hlRx='REC # / TYPE / VERS';
        hlAntType='ANT # / TYPE';
        hlAntPositionXyz='APPROX POSITION XYZ';
        hlAntDelHen='ANTENNA: DELTA H/E/N';
        hlAntDelXyz='ANTENNA: DELTA X/Y/Z';
        hlAntPhaseCenter='ANTENNA: PHASECENTER';
        hlAntBsightXyz='ANTENNA: B.SIGHT XYZ';
        hlAntZeroDirAzi='ANTENNA: ZERODIR AZI';
        hlAntZeroDirXyz='ANTENNA: ZERODIR XYZ';
        hlCntrMassXyz='CENTER OF MASS: XYZ';
        hlSysObs='SYS / # / OBS TYPES';
        hlSigStrength='SIGNAL STRENGTH UNIT';
        hlInterval='INTERVAL';
        hlTimeFirst='TIME OF FIRST OBS';
        hlTimeLast='TIME OF LAST OBS';
        hlRxClockOffset='RCV CLOCK OFFS APPL';
        hlSysDcbsAppl='SYS / DCBS APPLIED';
        hlSysPcvsAppl='SYS / PCVS APPLIED';
        hlSysScaleFactor='SYS / SCALE FACTOR';
        hlSysPhaseShift='SYS / PHASE SHIFT';
        hlGloSlot='GLONASS SLOT / FRQ #';
        hlGloCodPhsBis='GLONASS COD/PHS/BIS';
        hlLeapSec='LEAP SECONDS';
        hlNoSats='# OF SATELLITES';
        hlPrnObs='PRN / # OF OBS';
        hlEoh='END OF HEADER';
    end
    
    properties (Access=protected)
        % The optional header records
        validMarkerNumber=false;
        validAntPositionXyz=false;
        validAntDelXyz=false;
        validAntObsCode=false;
        validAntSatSys=false;
        validAntPhaseCntrIjk=false;
        validAntBsightXyz=false;
        validAntZeroDirAzi=false;
        validAntZeroDirXyz=false;
        validCntrMassXyz=false;
        validSigStrengthUnit=false;
        validInterval=false;
        validTimeLastObs=false;
        % TODO dcbs, scale factor,pcvs,
        validLeapSecs=false;
        validNumSvs=false;
        validNumObsPerSv=false;

    end
    
    properties
        lsf=[];
        wnLsf=[];
        dn=[];
        tsysid=[];
        markerName='';
        markerNumber='';
        markerType='';
        observer='';
        agency='';
        rxNumber='';
        rxType='';
        rxVersion='';
        antNumber='';
        antType='';
        antPositionXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
        antDelHen=containers.Map({'h','e','n'},{NaN,NaN,NaN});
        antDelXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
        antSatSys=rinex3SatId();
        antObsCode=rinex3ObsId();
        antPhaseCntrIjk=containers.Map({'i','j','k'},{NaN,NaN,NaN});
        antBsightXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
        antZeroDirAzi=NaN;
        antZeroDirXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
        cntrMassXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
        sigStrengthUnit='';
        interval=seconds(NaN);
        timeSystem=rinex3SatId();
        timeFirstObs=NaT;
        timeSecObs=NaT;
        timeLastObs=NaT;
        clckOffsetAppl=false;
        infoDcbs='';
        infoPcvs='';
        sysScaleFactor=NaN;
        sysPhaseShift=[rinex3PhaseShift()];
        glonassSlotFreq='';           % TODO
        glonassCodePhaseBias='';     % TODO
        numSvs=NaN;
        leapSecs='';                   
        numObsPerSv='';              % TODO
    end

    methods

        function obj=rinex3ObsHeader(~)
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
            obj.lsf=[];
            obj.wnLsf=[];
            obj.dn=[];
            obj.tsysid=(Nan);
            obj.markerName='';
            obj.markerNumber='';
            obj.markerType='';
            obj.observer='';
            obj.agency='';
            obj.rxNumber='';
            obj.rxType='';
            obj.rxVersion='';
            obj.antNumber='';
            obj.antType='';
            obj.antPositionXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
            obj.antDelHen=containers.Map({'h','e','n'},{NaN,NaN,NaN});
            obj.antDelXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
            obj.antSatSys=rinex3SatId();
            obj.antObsCode=rinex3ObsId();
            obj.antPhaseCntrIjk=containers.Map({'i','j','k'},{NaN,NaN,NaN});
            obj.antBsightXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
            obj.antZeroDirAzi=NaN;
            obj.antZeroDirXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
            obj.cntrMassXyz=containers.Map({'x','y','z'},{NaN,NaN,NaN});
            obj.sigStrengthUnit='';
            obj.interval=seconds(NaN);
            obj.timeSystem=rinex3SatId();
            obj.timeFirstObs=NaT;
            obj.timeSecObs=NaT;
            obj.timeLastObs=NaT;
            obj.clckOffsetAppl=false;
            obj.infoDcbs='';
            obj.infoPcvs='';
            obj.sysScaleFactor=NaN;
            obj.sysPhaseShift=[rinex3PhaseShift()];
            obj.glonassSlotFreq='';
            obj.glonassCodePhaseBias='';
            obj.leapSecs='';
            obj.numSvs=NaN;
            obj.numObsPerSv='';
            obj.validLeapSecs=false;
            obj.validCommentList=false;
            obj.validMarkerNumber=false;
            obj.validAntPositionXyz=false;
            obj.validAntDelXyz=false;
            obj.validAntObsCode=false;
            obj.validAntSatSys=false;
            obj.validAntPhaseCntrIjk=false;
            obj.validAntBsightXyz=false;
            obj.validAntZeroDirAzi=false;
            obj.validAntZeroDirXyz=false;
            obj.validCntrMassXyz=false;
            obj.validSigStrengthUnit=false;
            obj.validInterval=false;
            obj.validTimeLastObs=false;
            obj.validNumSvs=false;
            obj.validNumObsPerSv=false;       
        end

        % end of function clear
    
        %==============================
        function set.markerName(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>60
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 60 characters long.')
            else
                obj.markerName=i;
            end
        end
        end
        % end of function set.markerName

        %================================
        function set.markerNumber(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.markerNumber=i;
                obj.validMarkerNumber=true;
            end
        end
        end
        % end of function set.markerNumber

        %==============================
        function set.markerType(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.markerType=i;
            end
        end
        end
        % end of function set.markerType

        %===========================
        function set.observer(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.observer=i;
            end
        end
        end
        % end of function set.observer
        
        %=========================
        function set.agency(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>40
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.agency=i;
            end 
        end
        end
        % end of function set.agency

        %============================
        function set.rxNumber(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.rxNumber=i;
            end
        end
        end
        % end of function set.rxNumber

        %==========================
        function set.rxType(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.rxType=i;
            end 
        end
        end
        % end of function set.rxType

        %=============================
        function set.rxVersion(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.rxVersion=i;
            end 
        end
        end
        % end of function set.rxVersion
        
        %=================================
        function set.antNumber(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.antNumber=i;
            end
        end
        end
        % end of function set.antNumber

        %===============================
        function set.antType(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of string type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.antType=i;
            end
        end
        end
        % end of function set.antType

        %=======================================
        function set.antPositionXyz(obj,i)
        if ~isa(i,'containers.Map')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of containers.Map type, but not %s',class(i))
        else
            k=string(keys(i));
            c=['x','y','z'];
            if all(ismember(char(k),c))
                for m=c
                    if ~isa(i(m),'double')
                        error('rinex3ObsHeader:incorrectType',...
                            'input must be of containers.Map of doubles.')
                    else
                        obj.antPositionXyz(m)=i(m);
                    end
                end
                obj.validAntPositionXyz=...
                     any(isnan(cell2mat(values(obj.antPositionXyz))));
            else
                error('rinex3ObsHeader:badInput',...
                    'input containers.Map does not have required key/value')
            end
        end
        end
        % end of function set.antPositionXyz

        %==================================
        function set.antDelHen(obj,i)
        if ~isa(i,'containers.Map')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of containers.Map type, but not %s',class(i))
        else
            k=string(keys(i));
            c=['h','e','n'];
            if all(ismember(char(k),c))
                for m=c
                    if ~isa(i(m),'double')
                        error('rinex3ObsHeader:incorrectType',...
                            'input must be of containers.Map of doubles')
                    else
                        obj.antDelHen(m)=i(m);
                    end
                end
            else
                error('rinex3ObsHeader:badInput',...
                    'input containers.Map does not have required key/value')
            end
        end
        end
        % end of function set.antDelHen
    
        %==================================
        function set.antDelXyz(obj,i)
        if ~isa(i,'containers.Map')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of containers.Map type, but not %s',class(i))
        else
            k=string(keys(i));
            c=['x','y','z'];
            if all(ismember(char(k),c))
                for m=c
                    if ~isa(i(m),'double')
                        error('rinex3ObsHeader:incorrectType',...
                            'input must be of containers.Map of doubles')
                    else
                            obj.antDelXyz(m)=i(m);
                    end
                end
                obj.validAntDelXyz=...
                any(isnan(cell2mat(values(obj.antDelXyz))));
            else
                error('rinex3ObsHeader:badInput',...
                    'input containers.Map does not have required key/value')
            end
        end
        end
        % end of function set.antDelXyz
    
        %==================================
        function set.antSatSys(obj,i)
        if ~isa(i,'rinex3SatId')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of rinex3SatId type, but not %s',class(i))
        else
            obj.antSatSys=i;
            [bs,~]=obj.antSatSys.isValid();
            if bs && (obj.antSatSys.system~=satSysId.systemMixed)
                obj.validAntSatSys=true;
            end
        end
        end
        % end of function set.antSatSys

        %===================================
        function set.antObsCode(obj,i)
        if ~isa(i,'rinex3ObsId')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of rinex3ObsId type, but not %s',class(i))
        else

            obj.antObsCode=i;
            obj.validAntObsCode=obj.antObsCode.isValid();
        end
        end
        % end of function set.antObsCode

        %=========================================
        function set.antPhaseCntrIjk(obj,i)
        % xyz or enu (ijk)
        if ~isa(i,'containers.Map')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of containers.Map type, but not %s',class(i))
        else
            k=string(keys(i));
            c=['i','j','k'];
            if all(ismember(char(k),c))
                for m=c
                    if ~isa(i(m),'double')
                        error('rinex3ObsHeader:incorrectType',...
                            'input must be of containers.Map of doubles')
                    else
                        obj.antPhaseCntrIjk(m)=i(m);
                    end
                end
                obj.validAntPhaseCntrIjk=...
                    any(isnan(cell2mat(values(obj.antPhaseCntrIjk))));
            else
                error('rinex3ObsHeader:badInput',...
                    'input containers.Map does not have required key/value')
            end
        end
        end
        % end of function set.antPhaseCntrIjk

        %=====================================
        function set.antBsightXyz(obj,i)
        if ~isa(i,'containers.Map')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of containers.Map type, but not %s',class(i))
        else
            k=string(keys(i));
            c=['x','y','z'];
            if all(ismember(char(k),c))
                for m=c
                    if ~isa(i(m),'double')
                        error('rinex3ObsHeader:incorrectType',...
                            'input must be of containers.Map of doubles')
                    else
                        obj.antBsightXyz(m)=i(m);
                    end
                end
                obj.validAntBsightXyz=...
                    any(isnan(cell2mat(values(obj.antBsightXyz))));
            else
                error('rinex3ObsHeader:badInput',...
                    'input containers.Map does not have required key/value')
            end
        end
        end
        % end of function set.antBsightXyz

        %=======================================
        function set.antZeroDirAzi(obj,i)
        if ~isa(i,'double')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of double type, but not %s',class(i))
        else
            obj.antZeroDirAzi=i;
            obj.validAntZeroDirAzi=isnan(obj.antZeroDirAzi);
        end
        end
        % end of function set.antZeroDirAzi

        %=======================================
        function set.antZeroDirXyz(obj,i)
        if ~isa(i,'containers.Map')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of containers.Map type, but not %s',class(i))
        else
            k=string(keys(i));
            c=['x','y','z'];
            if all(ismember(char(k),c))
                for m=c
                    if ~isa(i(m),'double')
                        error('rinex3ObsHeader:incorrectType',...
                            'input must be of containers.Map of doubles')
                    else
                        obj.antZeroDirXyz(m)=i(m);
                    end
                end
                obj.validAntZeroDirXyz=...
                    any(isnan(cell2mat(values(obj.antZeroDirXyz))));
            else
                error('rinex3ObsHeader:badInput',...
                    'input containers.Map does not have required key/value')
            end           
        end
        end
        % end of function set.antZeroDirXyz

        %================================
        function set.cntrMassXyz(obj,i)
        if ~isa(i,'containers.Map')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of containers.Map type, but not %s',class(i))
        else
            k=string(keys(i));
            c=['x','y','z'];
            if all(ismember(char(k),c))
                for m=c
                    if ~isa(i(m),'double')
                        error('rinex3ObsHeader:incorrectType',...
                            'input must be of containers.Map of doubles')
                    else
                        obj.cntrMassXyz(m)=i(m);
                    end
                end
                obj.validCntrMassXyz=...
                    any(isnan(cell2mat(values(obj.cntrMassXyz))));
            else
                error('rinex3ObsHeader:badInput',...
                    'input containers.Map does not have required key/value')
            end
        end
        end
        % end of function set.cntrMassXyz      
        
        %====================================
        function set.sigStrengthUnit(obj,i)
        if ~ischar(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of char type, but not %s',class(i))
        else
            if length(i)>20
                error('rinex3ObsHeader:badInput',...
                    'input must not be longer than 20 characters long.')
            else
                obj.sigStrengthUnit=i;
                obj.validSigStrengthUnit=true;
            end
        end
        end
        % end of function set.sigStrengthUnit

        %===========================        
        function set.interval(obj,i)
        if ~isduration(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of duration type, but not %s',class(i))
        else
            obj.interval=i;
            obj.validInterval=~isnan(i);
        end
        end
        % end of function set.interval
        
        %==============================
        function set.timeSystem(obj,i)
        if ~isa(i,'rinex3SatId')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of type rinex3SatId, but not %s.',class(i))
        else
            if length(i)>1
                error('rinex3ObsHeader:badInput',...
                    'input must not be more than one rinex3SatId object.')
            else
                obj.timeSystem=i;
            end
            
        end
        end
        % end of function set.timeSystem
        
        %=================================
        function set.timeFirstObs(obj,i)
        if ~isdatetime(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of type datetime, but not %s.',class(i))
        else
            if length(i)>1
                error('rinex3ObsHeader:badInput',...
                    'input must not be more than one datetime object.')
            else
                obj.timeFirstObs=i;
            end
        end
        end
        % end of set.timeFirstObs

        %=================================
        function set.timeSecObs(obj,i)
        if ~isdatetime(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of type datetime, but not %s.',class(i))
        else
            if length(i)>1
                error('rinex3ObsHeader:badInput',...
                    'input must not be more than one datetime object.')
            else
                obj.timeSecObs=i;
            end
        end
        end
        % end of set.timeSecObs

        %================================
        function set.timeLastObs(obj,i)
        if ~isdatetime(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of type datetime, but not %s.',class(i))
        else
            if length(i)>1
                error('rinex3ObsHeader:badInput',...
                    'input must not be more than one datetime object.')
            else
                obj.timeLastObs=i;
                obj.validTimeLastObs=~isnat(i);
            end
        end        
        end
        % end of set.timeLastObs

        %===================================
        function set.clckOffsetAppl(obj,i)
        if ~islogical(i)
            error('rinex3ObsHeader:incorrectType',...
                'input must be of type logical, but not %s',class(i))
        else
            obj.clckOffsetAppl=i;
        end
        end
        % end of function clckOffsetAppl

        %============================
        function set.infoDcbs(obj,i)
%        warning('rinex3ObsHeader:notImplemented','TODO')
        obj.infoDcbs=i;
        end
        % end of function set.infoDcbs
    
        %============================
        function set.infoPcvs(obj,i)
%        warning('rinex3ObsHeader:notImplemented','TODO')
        obj.infoPcvs=i;
        end
        % end of function set.infoPcvs
    
        %===================================
        function set.sysScaleFactor(obj,i)
%        warning('rinex3ObsHeader:notImplemented','TODO')
        obj.sysScaleFactor=i;
        end
        % end of function set.sysScaleFactor

        %==================================
        function set.sysPhaseShift(obj,i)
        if ~isa(i,'rinex3PhaseShift')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of rinex3PhaseShift, but not %s',class(i))
        else
            obj.sysPhaseShift=i;
        end
        end
        % end of function set.sysPhaseShift
    
        %====================================
        function set.glonassSlotFreq(obj,i)
%        warning('rinex3ObsHeader:notImplemented','TODO')
        obj.glonassSlotFreq=i;
        end
        % end of function set.glonassSlotFreq

        %==========================================
        function set.glonassCodePhaseBias(obj,i)
%        warning('rinex3ObsHeader:notImplemented','TODO')
        obj.glonassCodePhaseBias=i;
        end
        % end of function set.glonassCodePhaseBias

        %===========================
        function set.leapSecs(obj,i)
            if ~isa(i,'double')
                error('rinex3ObsHeader:incorrectType',...
                    'input must be of double type, but not %s',class(i))
            else
                obj.leapSecs=i;   
                obj.validLeapSecs = true;
            end
        end
        % end of function set.leapSecs

        %==========================
        function set.numSvs(obj,i)
        if ~isa(i,'double')
            error('rinex3ObsHeader:incorrectType',...
                'input must be of type double, but not %s',class(i))
        else
            obj.numSvs=i;
            obj.validNumSvs=~isnan(i);
        end
        end
        % end of function set.numSvs

        %=================================
        function set.numObsPerSv(obj,i)
%        warning('rinex3ObsHeader:notImplemented','TODO')
        obj.numObsPerSv=i;
        end
        % end of function set.numObsPerSv

    end
    % end of methods

    methods(Static=true)
    %========
    function sps=sortPhaseShift(ps,ss)
    % SORTPHASESHIFT
    % ps:rinex3PhaseShift
    % ss:satSysId
    %   array of satellites to sort ps based on
    if ~isa(ps,'rinex3PhaseShift')
        error('rinex3ObsHeader:incorrectType',...
            'input must be of type rinex3PhaseShift, but not %s',class(ps))
    end
    lPs=length(ps);
    lSs=length(ss);
    mg=cell(1,lSs); % mildly ground stage:)
    counterMg=ones(1,lSs);
    for ii=1:lPs
        if ~ps(lPs).isValid()
            error('rinex3ObsHeader:invalid',...
                'input is not a valid rinex3PhaseShift object.')
        end
        
        % organize ps into length(ss) cells
        [lia,locb]=ismember(ps(ii).satellites(1).system,ss);
        if ~lia
            error('rinex3ObsHeader:invalid',...
                '%s does not belong with ss',ps(lPs).satellites(1).system)
        end
        mg{locb}(counterMg(locb))=ps(ii);
        counterMg(locb)=counterMg(locb)+1;

    end
    % in each cell, find the reference or add one
    % 2 cases=> 1: phase shift corrections are known
    %        => 2: corrections are not known
    % in case of 1, ps.satellites must contain only one
    % object with p=-1, and length(obsCodes)=length(correction)=0
    % in case of 2, ps.satellites may be (-1) or multiple of them 
    % and positive integers. length(obsCodes)>0
    
    counterSps=1;
    for ii=1:lSs
        % its enough to look at the first one
        switch mg{ii}(1).obsCode.observationType
            case obsType.unknown
                if length(mg{ii})>1
                    error('rinex3ObsHeader:invalid',...
                        ['rinex does not allow mixture of',...
                        ' known/unknwon phase shifts per satellite',...
                        ' system.'])
                end
                % Nothing is needed here 
                sps(counterSps)=mg{ii};
                counterSps=counterSps+1;

            case obsType.phase
                [g,c,zeta]=rinex3ObsHeader.getPhaseCorrection([mg{ii}.obsCode]);
                % build up the sorted rinex3PhaseShift if necessary
                lAug=length(g);
                lOrigObsList=length([mg{ii}.obsCode]);
                if lAug > lOrigObsList
                    % add the last element of g (by convention,
                    % the reference is added last if absent)
                    sps(counterSps:counterSps+lAug-1)=...
                        [mg{ii},...
                         rinex3PhaseShift(rinex3SatId(ss(ii)),g(end),c(end))];
                    counterSps=counterSps+lAug;
                else
                    % move it intact to sps
                    sps(counterSps:counterSps+lOrigObsList-1)=...
                        mg{ii};
                    counterSps=counterSps+lOrigObsList;
                end
        end

    end
    
    end
    % end of function sortPhaseShift
    
    %============================
    function [g,c,zeta]=getPhaseCorrection(k)
    % GETPHASECORRECTION
    % [g,c,zeta]=getPhaseCorrection(k) calculates phase correction of an array
    % of rinex3ObsId objects.
    % k:rinex3ObsId
    %   could be array also
    % c:double
    %   the corrections array
    % g:rinex3ObsId
    %   
    if ~isa(k,'rinex3ObsId')
        error('rinex3ObsHeader:incorrectType',...
            'input must be of type rinex3ObsId, but not %s',class(k))
    end
    ot=[k.observationType];
    cb=[k.carrierBand];
    tm=[k.trackingMode];
    ss=[k.system];
    areOnlyPhases=all(ismember(ot,obsType.phase));
    if ~areOnlyPhases
        error('rinex3ObsHeader:badInput',...
            ['input must be rinex3ObsId with observationType(s)',...
            ' equal to obsType.phase.'])
    end
    uSs=unique(ss);
    lus=length(uSs);
    c=NaN(1,length(ss));
    zeta=zeros(1,length(ss));
    g=k;
    if lus~=1
        error('rinex3ObsHeader:badInput',...
            ['input must be an array of rinex3ObsId object(s)',...
            ' belonging to the same satellite system.'])
    end
    if ismember(uSs,[satSysId.systemUnknown,satSysId.systemMixed])
        error('rinex3ObsHeader:badInput',...
            ['input must be an array of rinex3ObsId object(s)',...
            'from known satSysId satellite system(s).'])
    end
    % define refernece signals
    switch uSs
        case satSysId.systemGPS
            cbRef=[carrierBand.L1,carrierBand.L2,carrierBand.L5];
            tmRef=[trackingMode.CA,trackingMode.PP,trackingMode.I];
            
        case satSysId.systemGalileo
            cbRef=[carrierBand.E1,carrierBand.E5a,carrierBand.E5b,...
                    carrierBand.E5,carrierBand.E6];
            tmRef=[trackingMode.B,trackingMode.I,trackingMode.I,...
                    trackingMode.I,trackingMode.B];
                
        case satSysId.systemGLONASS
            cbRef=[carrierBand.G1,carrierBand.G1a,carrierBand.G2,...
                    carrierBand.G2a,carrierBand.G3];
            tmRef=[trackingMode.CA,trackingMode.A,trackingMode.CA,...
                    trackingMode.A,trackingMode.I];
                
        case satSysId.systemBDS
            cbRef=[carrierBand.B12,carrierBand.B1,carrierBand.B2a,...
                    carrierBand.B2b,carrierBand.B2b,carrierBand.B2,...
                    carrierBand.B3];
            tmRef=[trackingMode.I,trackingMode.DD,trackingMode.DD,...
                    trackingMode.I,trackingMode.DD,trackingMode.DD,...
                    trackingMode.I];
                
        case satSysId.systemQZSS
            cbRef=[carrierBand.L1,carrierBand.L5,carrierBand.L6];
            tmRef=[trackingMode.CA,trackingMode.DD,trackingMode.D];
        
        case satSysId.systemSBAS
            % It seems all of them could be references
            cbRef=[carrierBand.L1,carrierBand.L5,carrierBand.L5,...
                    carrierBand.IQ];
            tmRef=[trackingMode.CA,trackingMode.I,trackingMode.Q,...
                    trackingMode.IQ];
        
        case satSysId.systemIRNSS
            cbRef=[carrierBand.L5,carrierBand.S];
            tmRef=[trackingMode.A,trackingMode.A];
    end
    % determine if a reference observation is among k
    % from Table A.23 for for every frequency band of a satellite
    % system, there exists one reference signal. so locb1 can never contain
    % zero elements.
    [~,locb1]=ismember(cb,cbRef);
    [~,locb2]=ismember(tm,tmRef);
    [common,indcsRef,~]=intersect(locb1,locb2);
    switch ~isempty(common)
        case true
            % there is at least one reference signal
            indcsRef=indcsRef';
            zeta(indcsRef)=1;

        case false
            % none of them is a reference signal,
            % so add one reference signal to the array
            g=[g,rinex3ObsId(tmRef(1),cbRef(1),obsType.phase,uSs)];
            zeta=[zeta,1];
    end
    % fill up c
    for ii=1:length(g)
        c(ii)=rinex3ObsHeader.phaseCorrectionTable(g(ii));
    end
    end
    % end of function getPhaseCorrection
    %============================
    
    function c=phaseCorrectionTable(obsCode)
    % PHASECORRECTIONTABLE is realization of Table A.23
    % returns the correction in cycles, either a non-zero value
    % or NaN. The latter indicates none in the table.
    % This function does not indicate if obsCode is a reference
    % signal or not. refer to rinex3ObsHeader.getPhaseCorrection method.
    % obsCode:rinex3ObsId
    % c:double
    if ~isa(obsCode,'rinex3ObsId')
        error('rinex3ObsHeader:incorrectType',...
            'input must be of type rinex3ObsId, but not %s',class(k))
    end
    if length(obsCode)>1
        error('rinex3ObsHeader:badInput',...
            'input must be a scalar rinex3ObsId object.')
    end
    if obsCode.observationType~=obsType.phase
        error('obsCode must be a phase obsType, not %s.',...
            char(obsCode.observationType))
    end
    switch obsCode.system
        case satSysId.systemGPS
            switch obsCode.carrierBand
                case carrierBand.L1
                    switch obsCode.trackingMode
                        case trackingMode.CA
                            c=NaN;
                        otherwise
                            c=1/4;
                    end
                case carrierBand.L2
                    switch obsCode.trackingMode
                        case {trackingMode.CA,trackingMode.D,...
                              trackingMode.P,trackingMode.DP}
                            c=-1/4;
                        case {trackingMode.DD,trackingMode.PP,...
                              trackingMode.Z,trackingMode.N}
                            c=NaN;
                    end
                case carrierBand.L5
                    switch obsCode.trackingMode
                        case {trackingMode.I,trackingMode.IQ}
                            c=NaN;
                        case trackingMode.Q
                            c=-1/4;
                    end
            end
        case satSysId.systemGalileo
            switch obsCode.carrierBand
                case carrierBand.E1
                    switch obsCode.trackingMode
                        case {trackingMode.B,trackingMode.DP}
                            c=NaN;
                        case trackingMode.CA
                            c=1/2;
                    end
                case carrierBand.E5a
                    switch obsCode.trackingMode
                        case {trackingMode.I,trackingMode.IQ}
                            c=NaN;
                        case trackingMode.Q
                            c=-1/4;
                    end
                case carrierBand.E5b
                    switch obsCode.trackingMode
                        case {trackingMode.I,trackingMode.IQ}
                            c=NaN;
                        case trackingMode.Q
                            c=-1/4;
                    end
                case carrierBand.E5
                    switch obsCode.trackingMode
                        case {trackingMode.I,trackingMode.IQ}
                            c=NaN;
                        case trackingMode.Q
                            c=-1/4;
                    end
                case carrierBand.E6
                    switch obsCode.trackingMode
                        case {trackingMode.B,trackingMode.DP}
                            c=NaN;
                        case trackingMode.CA
                            c=-1/2;
                    end
            end
        case satSysId.systemUnknown
            error('rinex3ObsHeader:invalid',...
                'obsCode.system is %s.',char(obsCode.system))
        otherwise
            error('rinex3ObsHeader:notImplemented',...
                  'phase correction table for %s is not implemented.',...
                  char(obsCode.system))
    end
    end
    % end of function PhaseCorrectionTable
    
    end
    % end of methods

end
