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
function parse(obj,fileId)
% RINEX3OBSHEADER.PARSE
% fileId:integer
% reads the header of a rinex3 observation file. Currently not in use.
obj.clear();

isSysObsNoTypesRead=false;
isSysPhaseShiftRead=false;
isEoh=false;

line='';
while ~isEoh
    line=fgetl(fileId);
    line=strip(line,'right');
    
    ll=length(line);
    if ll==0
        error('???')
    elseif ll<60 || ll>80
        error('rinex3ObsHeader:invalid',...
            'invalid rinex3 header line at %dth line.',ftell(fileId))
    end

    label=line(61:end);

    switch label
        case obj.hlVer
            obj.version=str2double(strip(line(1:9),'both'));
            % 11X
            obj.fileType=line(21);
            % 19X
            fileSatSys=rinex3SatId();
            fileSatSys.fromchar(line(41));
            obj.fileSatSys=fileSatSys;
            %19X
        
        case obj.hlRunby
            obj.fileProgram=strip(line(1:20),'both');
            obj.fileAgency=strip(line(21:40),'both');
            obj.date=strip(line(41:60),'both');

        case obj.hlComment
            % first time encountering it
            if ~obj.validCommentList
                obj.commentList={strip(line(1:60),'right')};
            else
                commentList=obj.commentList;
                commentList{length(commentList)+1}=...
                            strip(line(1:60),'right');
                obj.commentList=commentList;
            end

        case obj.hlMarkerName
            obj.markerName=strip(line(1:60),'right');

        case obj.hlMarkerNumber
            obj.markerNumber=strip(line(1:20),'right');

        case obj.hlMarkerType
            obj.markerType=strip(line(1:20),'right');

        case obj.hlObs
           obj.observer=strip(line(1:20),'right');
           obj.agency=strip(line(21:60),'right');

        case obj.hlRx
           obj.rxNumber=strip(line(1:20),'right');
           obj.rxType=strip(line(21:40),'right');
           obj.rxVersion=strip(line(41:60),'right');

        case obj.hlAntType
            obj.antNumber=strip(line(1:20),'right');
            obj.antType=strip(line(21:40),'right');

        case obj.hlAntPositionXyz
            [antPos,nRead]=sscanf(line(1:42),'%f');
            if nRead==3
                obj.antPositionXyz=...
                    containers.Map({'x','y','z'},...
                            {antPos(1),antPos(2),antPos(3)});
            end

        case obj.hlAntDelHen
            [delHen,nRead]=sscanf(line(1:42),'%f');
            if nRead==3
                obj.antDelHen=...
                containers.Map({'h','e','n'},...
                        {delHen(1),delHen(2),delHen(3)});
            end
        
        case obj.hlAntDelXyz
            [delXyz,nRead]=sscanf(line(1:42),'%f');
            if nRead==3
                obj.antDelXyz=...
                    containers.Map({'x','y','z'},...
                            {delXyz(1),delXyz(2),delXyz(3)});
            end

        case obj.hlAntPhaseCenter
            antSatSys=rinex3SatId();
            antSatSys.fromchar(line(1));
            obj.antSatSys=antSatSys;
            %1X          
            antObsCode=rinex3ObsId();
            antObsCode.from3letter(strip(line(3:5),'both'),...
                                     antSatSys.system);
            obj.antObsCode=antObsCode;
            [antPhaseCntr,nRead]=sscanf(strip(line(1:37),'both'),'%f');
            if nRead==3
                obj.antPhaseCntrIjk=...
                    containers.Map(antPhaseCntr(1),antPhaseCntr(2),...
                                   antPhaseCntr(3));
            end

        case obj.hlAntBsightXyz
            [antBsight,nRead]=sscanf(line(1:42),'%f');
            if nRead==3
                obj.antBsightXyz=...
                    containers.Map({'x','y','z'},...
                                {antBsight(1),antBsight(2),antBsight(3)});
            end

        case obj.hlAntZeroDirAzi 
            [antZAzi,nRead]=sscanf(line(1:14),'%f');
            if nRead==1
                obj.antZeroDirAzi=antZAzi;
            end

        case obj.hlAntZeroDirXyz
            [antZXyz,nRead]=sscanf(line(1:42),'%f');
            if nRead==3
                obj.antZeroDirXyz=...
                    containers.Map({'x','y','z'},...
                        {antZXyz(1),antZXyz(2),antZXyz(3)});
            end

        case obj.hlCntrMassXyz
            [cntrMass,nRead]=sscanf(line(1:42),'%f');
            if nRead==3
                obj.cntrMassXyz=...
                    containers.Map({'x','y','z'},...
                        {cntrMass(1),cntrMass(2),cntrMass(3)});
            end

        case obj.hlSysObs
            r3sid=rinex3SatId();
            r3sid.fromchar(line(1));
            %2X
            noObs=sscanf(line(4:6),'%u');
            maxObsPerLine=13;
            ii=1;
            jj=1;
            obsCodesPerSys=[rinex3ObsId()];  
            for ii=1:noObs
                ndx=6+(jj-1)*4+1;
                obsI=strip(line(ndx:ndx+3),'left');
                r3oid=rinex3ObsId();
                r3oid.from3letter(obsI,r3sid.system);
                obsCodesPerSys(ii)=r3oid;
                jj=jj+1;
                % read the continuation line
                if ~mod(ii,maxObsPerLine)
                    line=fgetl(fileId);
                    line=strip(line,'right');
                    jj=1;
                end
            end
            
            r3otn=rinex3ObsTypeNum(r3sid,noObs,obsCodesPerSys);
            
            if ~isSysObsNoTypesRead
                obj.sysObsNoTypes=r3otn;
                isSysObsNoTypesRead=true;
            else
                obj.sysObsNoTypes=[obj.sysObsNoTypes,r3otn];
            end

        case obj.hlSigStrength
            obj.sigStrengthUnit=strip(line(1:20),'right');

        case obj.hlInterval
            obj.interval=seconds(sscanf(line(1:10),'%f'));

        case obj.hlTimeFirst
            [e1,n1read]=sscanf(line(1:30),'%u');
            [e2,n2read]=sscanf(line(31:43),'%f');
            if (n1read~=5)||(n2read~=1)
                error('???')%TODO
            end
            %5X
            % only compulsory in mixed GNSS files
            if obj.fileSatSys.system==satSysId.systemMixed
                timeSystem=rinex3SatId();
                timeSystem.from3letter(line(49:51));
            else    % TODO what if the system is not defined?
                timeSystem=rinex3SatId(obj.fileSatSys.system);
            end
            obj.timeSystem=timeSystem;
            obj.timeFirstObs=datetime(e1(1),e1(2),e1(3),e1(4),e1(5),e2);

        case obj.hlTimeLast
            [e1,n1read]=sscanf(line(1:30),'%u');
            [e2,n2read]=sscanf(line(31:43),'%f');
            if (n1read~=5)||(n2read~=1)
                error('???')%TODO
            end
            obj.timeLastObs=datetime(e1(1),e1(2),e1(3),e1(4),e1(5),e2);

        case obj.hlRxClockOffset
            obj.clckOffsetAppl=logical(sscanf(line(1:6),'%u'));

        case obj.hlSysDcbsAppl
            % TODO cast a notImplemented warning
            warning('SYS / DCBS APPLIED header is not implemented.')
            obj.infoDcbs='';

        case obj.hlSysPcvsAppl
            warning('SYS / PCVS APPLIED header is not implemented.')
            obj.infoPcvs='';

        case obj.hlSysScaleFactor
            error('SYS / SCALE FACTOR header is not implemented.')
            obj.sysScaleFactor='';

        case obj.hlSysPhaseShift
            % two cases:
            % 1. phase corrections are unknown
            % satellite system is indicated, the rest is blank
            %   
            % 2. they are known
            % satellite system & observation code are inidcated
            % but the correction could be blank.
            %
            % I guess one file can have mix of both cases for different
            % systems.
            r3sidLine=rinex3SatId();
            r3sidLine.fromchar(line(1));
            ss=r3sidLine.system;
            c=NaN;

            obsLine=rinex3ObsId();
            if ~isempty(strip(line(3:5),'both'))
                obsLine.from3letter(line(3:5),ss);
                
                [c,nRead]=sscanf(line(7:14),'%f');
                % if nRead=0, matlab does c=[]
                if nRead==0
                    c=NaN;
                end
                % 1X
                [numSats,nRead]=sscanf(line(17:18),'%u');
                if (nRead>0 && numSats>0)
                    % read the list of satellites
                    maxSatsPerLine=10;
                    numLines=ceil(numSats/maxSatsPerLine);
                    p=[];
                    for jj=1:numLines
                        p=[p,sscanf(line(19:58),'%u')];
                        line=fgetl(fileId);
                    end
                    
                    if length(p)~=numSats
                        error('rinex3ObsHeader:invalid',...
                            'number of satellites in %s is inconsistent.',...
                            obj.hlSysPhaseShift)
                    end

                    for ii=1:numSats
                        r3sidLine(ii)=rinex3SatId(ss,p(ii));
                    end
                end
            end
            
            r3ps=rinex3PhaseShift(r3sidLine,obsLine,c);
            if ~isSysPhaseShiftRead
                obj.sysPhaseShift=r3ps;
                isSysPhaseShiftRead=true;
            else
                obj.sysPhaseShift=[obj.sysPhaseShift,r3ps];
            end

        case obj.hlGloSlot
%            warning('GLONASS SLOT / FREQ # header is not implemented.')
        
        case obj.hlGloCodPhsBis
%            warning('GLONASS COD/PHS/BIS header is not implemented.')

        case obj.hlLeapSec
            warning('LEAP SECONDS header is not implemented.')

        case obj.hlNoSats
            obj.numSvs=sscanf(line(1:6),'%u');

        case obj.hlPrnObs
            warning('PRN / # OF OBS is not implemented.')

        case obj.hlEoh
            isEoh=true;

    end

end

%at this point, header object must be complete
if ~obj.isValid()
    error('%s does not contain a valid rinex header.',fopen(fileId))
end

end
