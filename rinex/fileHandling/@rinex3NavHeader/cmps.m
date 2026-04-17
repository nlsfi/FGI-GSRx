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
% CMPS composes rinex 3.04 navigation header file
%
% Inputs: 
%   obj:rinex3NavHeader
%   fileId:fid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~obj.isValid()
    error('rinex3ObsHeader:invalid',...
        'contents of the header do not qualify.')
end

% version / type
line={sprintf('%9.2f',obj.version)};
line=strcat(line,{repmat(' ',1,11)});

line=strcat(line,{sprintf('%c',obj.fileType)});
line=strcat(line,{repmat(' ',1,19)});

line=strcat(line,{sprintf('%c',obj.fileSatSys.aschar())});
line=strcat(line,{repmat(' ',1,19)});

line=strcat(line,{sprintf('%-20s',obj.hlVer)},{'\n'});
fprintf(fileId,line{1});

% pgm / run by / date
line={sprintf('%-20s',obj.fileProgram)};
line=strcat(line,{sprintf('%-20s',obj.fileAgency)});
dateNow=char(datetime('now','TimeZone','UTC','Format','yyyyMMdd HHmmss'));
dateC=strcat({dateNow},{' UTC'});
obj.date=dateC{1};
line=strcat(line,{sprintf('%-20s',obj.date)});
line=strcat(line,{sprintf('%-20s',obj.hlRunby)},{'\n'});
fprintf(fileId,line{1});

% comment
if obj.validCommentList
    n_comments=length(obj.commentList);
    for i=1:n_comments
        line={sprintf('%-60s',obj.commentList{i})};
        line=strcat(line,{sprintf('%-20s',obj.hlComment)},{'\n'});
        fprintf(fileId,line{1});
    end
end

% IONO CORR
% data validation todo
if obj.validIonoCorr
    systems = obj.ionoCorr;
    c = fieldnames(systems); % go trough all time sys corrections e.g., gps and gal

    for i = 1:numel(c)
        T = systems.(c{i});
        line = sprintf('%-4s %12.4E%12.4E%12.4E%12.4E %-1s %2d  %-20s', ...
            T.type, T.params(1), T.params(2), T.params(3), T.params(4), ...
            T.timeMark, T.svid, obj.hlIonoCorr);
        
        line = pad(line, 80, 'right');
        fprintf(fileId, '%s\n', line);
    end
end

% TIME SYS CORR
% data validation todo 
if obj.validTimesysCorr
    systems = obj.timesysCorr;
    c = fieldnames(systems); % go trough all time sys corrections e.g., gps and gal

    for i = 1:numel(c)
        T = systems.(c{i});
        line = sprintf('%-4s %17.10E%16.9E %6d %4d %-5s %2d %-20s', ...
            T.label, T.a0, T.a1, round(T.tref), T.week, T.src, T.utcId, obj.hlTimesysCorr);
        
        line = pad(line, 80, 'right');
        fprintf(fileId, '%s\n', line);
    end
end



% LEAP SECONDS
if obj.validLeapSecs
    line = sprintf('%6d%6d%6d%6d%-3s%33s%s', ...
        obj.leapSecs, obj.lsf, obj.wnLsf, obj.dn, obj.tsysid, '', obj.hlLeapSec);
    line = pad(line, 80, 'right');
    fprintf(fileId, '%s\n', line);
end

% end of header
line={repmat(' ',1,60)};
line=strcat(line,{sprintf('%-20s',obj.hlEoh)});
line = pad(line, 80, 'right');
line=strcat(line,{'\n'});
fprintf(fileId,line{1});

end
