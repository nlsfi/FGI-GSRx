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
function writeRinex3Obs(obsData,navData,...
                        fgiSettings,ot,fN,hD)

import helperfunctions.*
%                   WRITERINEX3OBS
% writeRinex3Obs(obsData,navData,fgiSettings,ot,fN,hD) 
% creates a ASCII file conforming to rinex 3.04 rules. 
% The file name is generated partly based on fN and 
% partly based on the obsData. If created successfully,
% it is written into a directory defined by fN.dir. 
%
% NB. This file is prepared to work with the output of the FGI-GSRX3 only.
%
% Inputs:
%   obsData:struct         - Observation data from FGI-GSRx
%   navData:struct         - Navigation data from FGI-GSRx
%   fgiSettings:struct     - FGI-GSRx settings
%   ot:obsType              - Array of obsType for rinex file to include.
%   fN:struct              - Naming information
%   hD:struct              - Header information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

r3oh=rinex3ObsHeader();
switch nargin
    case {1,2,3,4}
        error('not enough input arguments.')
    case 5
        if ~isstruct(fN)
            error('dir input must be of type struct.')          
        else
            % default rinex header info. 
            r3oh.version=3.04;
            r3oh.fileType='O';
            r3oh.fileProgram='FGI-GSRX3';
            r3oh.fileAgency='FGI';
            % date is calculated within rinex3ObsHeader.cmps()
            r3oh.commentList={'WRITE COMMENTS HERE'};
            r3oh.markerName='WRITE HERE';
            r3oh.markerNumber='WRITE HERE';
            r3oh.markerType='WRITE HERE';
            r3oh.observer='WRITE HERE';
            r3oh.agency='WRITE HERE';
            r3oh.rxNumber='WRITE HERE';
            r3oh.rxType='WRITE HERE';
            r3oh.rxVersion='WRITE HERE';
            r3oh.antNumber='WRITE HERE';
            r3oh.antType='WRITE HERE';
            r3oh.antDelHen=containers.Map({'h','e','n'},{0,0,0});
        end
        
    case 6
        if ~isstruct(hD)
            error('hD input must be of type struct.')
        else
            f=fieldnames(hD);
            p=properties(r3oh);
            for ii=1:length(f)
                [lia,locb]=ismember(f(ii),p);
                if lia~=1
                    error(['fields of dir must be exact same as',...
                            'properties of rinex3ObsHeader.'])
                else
                    r3oh.(f{ii})=getfield(hD,f{ii});
                end
            end
        end
end

% current supported signals (in FGI-GSr3) include:
% gpsl1,gpsl1c, gpsl5I,gpsl2cm
% gale1b,gale5,gale5bI,gale5bQ,gale5aI,gale5aQ,
% glol1,
% beib1,
% navicl5

satSystems=fieldnames(obsData);
fileSatSys=inferSatSystem(satSystems);
r3oh.fileSatSys=fileSatSys;
r3oh.leapSecs = fgiSettings.nav.gpsLeapSecond;
sysObsNoTypes=getSysObsNoTypes(obsData,ot);
    r3oh.sysObsNoTypes=sysObsNoTypes;

[tfo,tso,tlo,ts]=getTimeObs(obsData, fgiSettings);
r3oh.timeSystem=ts;
r3oh.timeSecObs=tso; %% for interval calculations
r3oh.timeFirstObs=tfo;
r3oh.timeLastObs=tlo;
r3oh.sysPhaseShift=getSysPhaseShift(sysObsNoTypes);
ff=fullfile(fN.dir,generateFileName(r3oh,fgiSettings,fN));
fd=fopen(ff,'w');
try
    r3oh.cmps(fd);
    for epochCount=1:length(navData)
        meas=getMeasurements(obsData,r3oh,epochCount, fgiSettings);
        r3od=rinex3ObsData(); 
        r3od.setObs(meas,r3oh);
        r3od.cmps(fd,r3oh);
    end
    fclose(fd);
catch ME
    rethrow(ME)
    fclose(fd);
end
end
