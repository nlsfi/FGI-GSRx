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
function cmps(obj,fileId)
% RINEX3ObsHeader.CMPS composes rinex 3.04 header for an observation file

if ~obj.isValid()
    error('rinex3ObsHeader:invalid',...
        'contents of the header do not qualify.')
end

% RINEX VERSION / FILE TYPE / SATELLITE SYSTEM / HEADER COMMENT
line={sprintf('%9.2f',obj.version)};
line=strcat(line,{repmat(' ',1,11)});
line=strcat(line,{sprintf('%c',obj.fileType)});
line=strcat(line,{repmat(' ',1,19)});
line=strcat(line,{sprintf('%c',obj.fileSatSys.aschar())});
line=strcat(line,{repmat(' ',1,19)});
line=strcat(line,{sprintf('%-20s',obj.hlVer)},{'\n'});
fprintf(fileId,line{1});

% TODO the date logic is redundat
% PGM / RUN BY / DATE
line={sprintf('%-20s',obj.fileProgram)};
line=strcat(line,{sprintf('%-20s',obj.fileAgency)});
dateNow=char(datetime('now','TimeZone','UTC','Format','yyyyMMdd HHmmss'));
dateC=strcat({dateNow},{' UTC'});
obj.date=dateC{1};
line=strcat(line,{sprintf('%-20s',obj.date)});
line=strcat(line,{sprintf('%-20s',obj.hlRunby)},{'\n'});
fprintf(fileId,line{1});

% COMMENTS
if obj.validCommentList
    nComments=length(obj.commentList);
    for i=1:nComments
        line={sprintf('%-60s',obj.commentList{i})};
        line=strcat(line,{sprintf('%-20s',obj.hlComment)},{'\n'});
        fprintf(fileId,line{1});
    end
end

% MARKER NAME
line={sprintf('%-60s',obj.markerName)};
line=strcat(line,{sprintf('%-20s',obj.hlMarkerName)},{'\n'});
fprintf(fileId,line{1});

% MARKER NUMBER
if obj.validMarkerNumber
    line={sprintf('%-20s',obj.markerNumber)};
    line=strcat(line,{repmat(' ',1,40)});
    line=strcat(line,{sprintf('%-20s',obj.hlMarkerNumber)},{'\n'});
    fprintf(fileId,line{1});
end

% MARKER TYPE
line={sprintf('%-20s',obj.markerType)};
line=strcat(line,{repmat(' ',1,40)});
line=strcat(line,{sprintf('%-20s',obj.hlMarkerType)},{'\n'});
fprintf(fileId,line{1});

% OBSERVER / AGENCY
line={sprintf('%-20s%-40s',obj.observer,obj.agency)};
line=strcat(line,{sprintf('%-20s',obj.hlObs)},{'\n'});
fprintf(fileId,line{1});

% RECEIVER NUMBER / TYPE / VERSION
line={sprintf('%-20s%-20s%-20s',obj.rxNumber,obj.rxType,obj.rxVersion)};
line=strcat(line,{sprintf('%-20s',obj.hlRx)},{'\n'});
fprintf(fileId,line{1});

% ANTENNA NUMBER / TYPE
line={sprintf('%-20s%-20s',obj.antNumber,obj.antType)};
line=strcat(line,{repmat(' ',1,20)});
line=strcat(line,{sprintf('%-20s',obj.hlAntType)},{'\n'});
fprintf(fileId,line{1});

% APPROX POSITION XYZ
if obj.validAntPositionXyz
    line={sprintf('%14.4f%14.4f%14.4f',obj.antPositionXyz('x'),...
                                       obj.antPositionXyz('y'),...
                                       obj.antPositionXyz('z'))};
    line=strcat(line,{repmat(' ',1,18)});
    line=strcat(line,{sprintf('%-20s',obj.hlAntPosXyz)},{'\n'});
    fprintf(fileId,line{1});
end

% ANTENNA DELTA H/E/N
line={sprintf('%14.4f%14.4f%14.4f',obj.antDelHen('h'),...
                                   obj.antDelHen('e'),...
                                   obj.antDelHen('n'))};
line=strcat(line,{repmat(' ',1,18)});
line=strcat(line,{sprintf('%-20s',obj.hlAntDelHen)},{'\n'});
fprintf(fileId,line{1});

% ANTENNA DELTA XYZ
if obj.validAntPositionXyz
    line={sprintf('%14.4f%14.4f%14.4f',obj.antPositionXyz('x'),...
                                       obj.antPositionXyz('y'),...
                                       obj.antPositionXyz('z'))};
    line=strcat(line,{repmat(' ',1,18)});
    line=strcat(line,{sprintf('%-20s',obj.hlAntDelXyz)},{'\n'});
    fprintf(fileId,line{1});
end

% ANTENNA PHASE CENTER
if (obj.validAntObsCode && obj.validAntSatSys &&...
   obj.validAntPhaseCntrIjk)

    line={sprintf('%c',obj.antSatSys.aschar())};
    line=strcat(line,{sprintf(' %3s',obj.antObsCode.as3letter())});
    line=strcat(line,{sprintf('%9.4f%14.4f%14.4f',...
                              obj.antPhaseCntrIjk('i'),...
                              obj.antPhaseCntrIjk('j'),...
                              obj.antPhaseCntrIjk('k'))});


    line=strcat(line,{repmat(' ',1,18)});
    line=strcat(line,{sprintf('%-20s',obj.hlAntPhaseCntr)},{'\n'});
    fprintf(fileId,line{1});
end

% ANTENNA BSIGHT XYZ
if obj.validAntBsightXyz
    line={sprintf('%14.4f%14.4f%14.4f',obj.antBsightXyz('x'),...
                                       obj.antBsightXyz('y'),...
                                       obj.antBsightXyz('z'))};
    line=strcat(line,{repmat(' ',1,18)});
    line=strcat(line,{sprintf('%-20s',obj.hlAntBsight)},{'\n'});
    fprintf(fileId,line{1});
end

% ANTENNA ZERODIR AZI
if obj.validAntZeroDirAzi
    line={sprintf('%14.4f',obj.antZeroDirAzi)};
    line=strcat(line,{repmat(' ',1,46)});
    line=strcat(line,{sprintf('%-20s',obj.hlAntZeroDirAzi)},{'\n'});
    fprintf(fileId,line{1});
end

% ANTENNA ZERODIR XYZ
if obj.validAntZeroDirXyz
    line={sprintf('%14.4f%14.4f%14.4f',obj.antZeroDirXyz('x'),...
                                       obj.antZeroDirXyz('y'),...
                                       obj.antZeroDirXyz('z'))};
    line=strcat(line,{repmat(' ',1,18)});
    line=strcat(line,{sprintf('%-20s',obj.hlAntZeroDirXyz)},{'\n'});
    fprintf(fileId,line{1});
end

% CENTER OF MASS XYZ
if obj.validCntrMassXyz
    line={sprintf('%14.4f%14.4f%14.4f',obj.cntrMassXyz('x'),...
                                       obj.cntrMassXyz('y'),...
                                       obj.cntrMassXyz('z'))};
    line=strcat(line,{repmat(' ',1,18)});
    line=strcat(line,{sprintf('%-20s',obj.hlCntrMassXyz)});
    line=strcat(line,{'\n'});
    fprintf(fileId,line{1});
end

% SYS / # OF OBS TYPES
for i=1:length(obj.sysObsNoTypes)
    line={sprintf('%c',obj.sysObsNoTypes(i).satellite.aschar())};
    line=strcat(line,{sprintf('  %3u',obj.sysObsNoTypes(i).noObs)});

    for exhObs=1:obj.sysObsNoTypes(i).noObs
        obsType=obj.sysObsNoTypes(i).obsCodes(exhObs).as3letter();
        line=strcat(line,{sprintf(' %3s',obsType)});        
        if ~mod(exhObs,13)
            % once it hits 13
            % write out the line and start a new line
            line=strcat(line,{repmat(' ',1,2)});
            line=strcat(line, {sprintf('%-20s',obj.hlSysObs)});
            line=strcat(line,{'\n'});
            fprintf(fileId,line{1});
            line={repmat(' ',1,6)};
            
        end
    end
    % the continuation lines
    llAdd=length(line{1});
    if llAdd>6
        line=strcat(line,{repmat(' ',1,60-llAdd)});
        line=strcat(line,{sprintf('%-20s',obj.hlSysObs)});
        line=strcat(line,{'\n'});
        fprintf(fileId,line{1});
    end
end

% SIGNAL STRENGTH UNIT
if obj.validSigStrengthUnit
    line={sprintf('%-20s',obj.sigStrengthUnit)};
    line=strcat(line,{repmat(' ',1,40)});
    line=strcat(line,{sprintf('%-20s',obj.hlSigStrength)});
    line=strcat(line,{'\n'});
    fprintf(fileId,line{1});
end

% INTERVAL
if (~obj.validInterval && obj.validTimeLastObs)
    % consistency of time systems is verified before in isValid
    t2=obj.timeSecObs;
    t1=obj.timeFirstObs;
    interval=t2-t1;
    obj.interval=interval;
end

if obj.validInterval
    line={sprintf('%10.3f',seconds(obj.interval))};
    line=strcat(line,{repmat(' ',1,50)});
    line=strcat(line,{sprintf('%-20s',obj.hlInterval)});
    line=strcat(line,{'\n'});
    fprintf(fileId,line{1});
end

% TIME OF FIRST OBS
fs=strcat({repmat('%6u',1,5)},{'%13.7f'});
fs=strcat(fs,{repmat(' ',1,5)});
fs=strcat(fs,{'%3s'});
line={sprintf(fs{1},obj.timeFirstObs.Year,...
                    obj.timeFirstObs.Month,...
                    obj.timeFirstObs.Day,...
                    obj.timeFirstObs.Hour,...
                    obj.timeFirstObs.Minute,...
                    obj.timeFirstObs.Second,...
                    obj.timeSystem.as3letter())};
line=strcat(line,{repmat(' ',1,9)});
line=strcat(line,{sprintf('%-20s',obj.hlTimeFirst)});
line=strcat(line,{'\n'});
fprintf(fileId,line{1});

% TIME OF LAST OBS
if obj.validTimeLastObs
    fs=strcat({repmat('%6u',1,5)},{'%13.7f'});
    fs=strcat(fs,{repmat(' ',1,5)});
    fs=strcat(fs,{'%3s'});
    line={sprintf(fs{1},obj.timeLastObs.Year,...
                        obj.timeLastObs.Month,...
                        obj.timeLastObs.Day,...
                        obj.timeLastObs.Hour,...
                        obj.timeLastObs.Minute,...
                        obj.timeLastObs.Second,...
                        obj.timeSystem.as3letter())};
    line=strcat(line,{repmat(' ',1,9)});
    line=strcat(line,{sprintf('%-20s',obj.hlTimeLast)});
    line=strcat(line,{'\n'});
    fprintf(fileId,line{1});
end

% RX CLOCK OFFSET APPLIED
% its more sensible to always write out clock offset
if obj.clckOffsetAppl
    line={sprintf('%6u',1)};
else
    line={sprintf('%6u',0)};
end
line=strcat(line,{repmat(' ',1,54)});
line=strcat(line,{sprintf('%-20s',obj.hlRxClockOffset)});
line=strcat(line,{'\n'});
fprintf(fileId,line{1});
% TODO dcbs, scaleFactor,pcvs

% SYS / PHASE SHIFT
for i=1:length(obj.sysPhaseShift)
    line={sprintf('%c ',...
            obj.sysPhaseShift(i).satellites(1).aschar())};
    
    line=strcat(line,{sprintf('%3s ',...
            obj.sysPhaseShift(i).obsCode.as3letter())});
    
    if ~isnan(obj.sysPhaseShift(i).correction)
        line=strcat(line,{sprintf('%8.5f',...
                obj.sysPhaseShift(i).correction)});   
    else
        line=strcat(line,{repmat(' ',1,8)});
    end

    % I don't need to check for unknown prns(-1)
    % because its already been taken care of in rinex3PhaseShift
    if obj.sysPhaseShift(i).satellites(1).p==-1
        line=strcat(line,{'    '});
    else
        noSats=length(obj.sysPhaseShift(i).satellites);
        line=strcat(line,{sprintf('  %2u',noSats)});
        for j=1:noSats
            line=strcat(line,...
                {sprintf(' %3u',obj.sysPhaseShift(i).satellites(j).p)});
            if ~mod(j,10)
                line=strcat(line,{'  '});
                line=strcat(line,{sprintf('%-20s',obj.hlSysPhaseShift)});
                line=strcat(line,{'\n'});
                fprintf(fileId,line{1});
                line={repmat(' ',1,18)};
            end
        end        
    end
    ll_p=length(line{1});
    line=strcat(line,{repmat(' ',1,60-ll_p)});
    line=strcat(line,{sprintf('%-20s',obj.hlSysPhaseShift)});
    line=strcat(line,{'\n'});
    fprintf(fileId,line{1});
end 


% TODO GLONASS SLOT/...
line={repmat(' ',1,60)};
line=strcat(line,sprintf('%-20s',obj.hlGloSlot));
line=strcat(line,{'\n'});
fprintf(fileId,line{1});


% TODO GLONASS COD/PHS/...
line={repmat(' ',1,60)};
line=strcat(line,sprintf('%-20s',obj.hlGloCodPhsBis));
line = pad(line, 80, 'right');
fprintf(fileId, '%s\n',line{1});

% LEAP SECONDS
if obj.validLeapSecs
    line = sprintf('%6d%6d%6d%6d%-3s%33s%s', ...
        obj.leapSecs, obj.lsf, obj.wnLsf, obj.dn, obj.tsysid, '', obj.hlLeapSec);
    line = pad(line, 80, 'right');
    fprintf(fileId, '%s\n', line);
end

if obj.validNumSvs
    line={sprintf('%6u',obj.numSvs)};
    line=strcat(line,{repmat(' ',1,54)});
    line=strcat(line,{sprintf('%-20s',obj.hlNoSats)});
    line=strcat(line,{'\n'});
    fprintf(fileId,line{1});
end

% TODO PRN / # OF OBS
if obj.validNumObsPerSv
    true;
end

line={repmat(' ',1,60)};
line=strcat(line,{sprintf('%-20s',obj.hlEoh)});
line=strcat(line,{'\n'});
fprintf(fileId,line{1});

end
