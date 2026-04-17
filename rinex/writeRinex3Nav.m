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
function writeRinex3Nav(obsData,navData,ephData,...
                        fgiSettings,ot,fN,hD)
% WRITERINEX3Nav creates a ASCII file conforming to rinex 3.04 rules. 
%
% The file name is generated partly based on fN and 
% partly based on the navData. If created successfully,
% it is written into a directory defined by fN.dir. 
%
% NB. This file is prepared to work with the output of the FGI-GSRX3 only.
%
% Inputs:
%   obsData:struct         - Observation data from FGI-GSRx
%   navData:struct         - Navigation data from FGI-GSRx
%   ephData:struct          - Ephemeris data from FGI-GSRx
%   fgiSettings:struct     - FGI-GSRx settings
%   ot:obsType              - Array of obsType for rinex file to include.
%   fN:struct              - Naming information
%   hD:struct              - Header information
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
import helperfunctions.*
r3nh=rinex3NavHeader();
switch nargin
    case {1,2,3,4,5}
        error('not enough input arguments.')
    case 6
        if ~isstruct(fN)
            error('dir input must be of type struct.')          
        else
            % default rinex header info. 
            r3nh.version=3.04;
            r3nh.fileType='N';
            r3nh.fileProgram='FGI-GSRX3';
            r3nh.fileAgency='FGI';
            r3nh.commentList={'WRITE COMMENTS HERE'}; 
        end
        
    case 7
        if ~isstruct(hD)
            error('hD input must be of type struct.')
        else
            f = fieldnames(hD);
            p=properties(r3nh);
            for ii=1:length(f)
                [lia,locb]=ismember(f(ii),p);
                if lia~=1
                    error(['fields of dir must be exact same as ',...
                            'properties of rinex3NavHeader.'])
                else
                    r3nh.(f{ii})=getfield(hD,f{ii});
                end
            end
        end
    end


% current supported signals include:
% gpsl1,gpsl5I,gpsl2cm
% gale1b,gale5,gale5bI,gale5bQ,gale5aI,gale5aQ,

satSystems=fieldnames(obsData);
fileSatSys=inferSatSystem(satSystems);
r3nh.fileSatSys=fileSatSys;
[tfo,tlo,ts]=getTimeObs(obsData, fgiSettings);

%r3nh.time_system=ts;
r3nh.timeFirstObs=tfo;
%r3nh.time_last_obs=tlo;

r3nh.leapSecs = fgiSettings.nav.gpsLeapSecond;

ff=fullfile(fN.dir,generateFileName(r3nh,fgiSettings,fN));
fd=fopen(ff,'w');
try
    ionocorr = getIonoCorr(ephData); % get iono-corr info
    r3nh.ionoCorr = ionocorr;

    tscorr = getTimesysCorr(ephData); % get time sys corr info
    r3nh.timesysCorr = tscorr;

    r3nh.cmps(fd); % compose header
    
    % compose data
    for i=1:fgiSettings.sys.nrOfSignals
        signame = fgiSettings.sys.enabledSignals{i};

        % get measurements for this signal
        measArray = getNavMeasurements(ephData, signame, obsData.(signame), fgiSettings);
        r3nd = rinex3NavData();
        r3nd.setNav(measArray, r3nh);
        for ii=1:numel(r3nd.observations{1})
           r3nd.cmps(fd, r3nh, ii); % compose data for this measurement
        end
    end
    fclose(fd);
catch ME
    rethrow(ME)
    fclose(fd);
end
end