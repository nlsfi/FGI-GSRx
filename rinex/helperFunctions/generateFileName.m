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
function fn=generateFileName(r3h,fgiSettings,md)
% GENERATEFILENAME generates the rinex file name based on given attributes from launcher.
% 
% Inputs:
%   r3h:struct              - Header information
%   fgiSettings:struct     - Settings from FGI-GSRx
%   md:struct               - Naming information
%
% Outputs:
%   fn:char vector          - File name
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

fn=strcat(md.projectName,'0',md.countryCode);
% fn='5Give0FIN'; %XXXXMRCCC
fn=strcat(fn,'_');

fn=strcat(fn,md.dataSource);  %R
fn=strcat(fn,'_');

tfo=r3h.timeFirstObs;
dateNum=datenum(tfo.Year,tfo.Month,tfo.Day)-...
         datenum(tfo.Year,1,0);
cTfo=sprintf('%4u%03u%02u%02u',...
              tfo.Year,...
              dateNum,...
              tfo.Hour,...
              tfo.Minute);
fn=strcat(fn,cTfo);
fn=strcat(fn,'_');

% To get the length, we need to look at the time of first and last observation.
if ~isnan(r3h.interval)
    if 60<seconds(r3h.interval) && seconds(r3h.interval)<3600
        fn=strcat(fn,sprintf('%02uM',floor(r3h.interval/60.)));    %minute
    elseif 3600<=seconds(r3h.interval) && seconds(r3h.interval)<86400
        fn=strcat(fn,sprintf('%02uH',floor(r3h.interval/3600.)));   %hour
    elseif 86400<=seconds(r3h.interval) && seconds(r3h.interval)<31536000
        fn=strcat(fn,sprintf('%02uD',floor(r3h.interval/86400.)));  %day
    elseif seconds(r3h.interval)>=31536000
        fn=strcat(fn,sprintf('%02uY',floor(r3h.interval/31536000.)));%year
    end
else
    fn=strcat(fn,'00U');
end
fn=strcat(fn,'_');

% To get the file update frequency 
if r3h.fileType == 'O'
    freq=1000./fgiSettings.nav.navSolPeriod;
    if 1/60<=freq && freq<1
        fn=strcat(fn,sprintf('%02S',floor(1/freq)));
    elseif 1<=freq && freq<100
        fn=strcat(fn,sprintf('%02uZ',floor(freq)));
    elseif 100<=freq
        fn=strcat(fn,sprintf('%02uC',floor(freq)));
    end
    fn=strcat(fn,'_');
end


fn=strcat(fn,sprintf('%c%c',r3h.fileSatSys.aschar(),r3h.fileType));
fn=strcat(fn,'.');
fn=strcat(fn,'rnx');

end