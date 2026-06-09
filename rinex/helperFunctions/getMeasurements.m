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
function m=getMeasurements(obsData,r3oh,c, settings)
% GETMEASUREMENTS
% assume what?
% It is writing NaN, if the measurement is not available
% e.g. t_12c.txt =>gale1b channel 5 except carrier frequency nothing is
% written out.
%
% obsData:structure
% r3oh:rinex3ObsHeader
% c:double
%   indicates the index
% m:cell
m={};
iM=1;
% TODO as of now, none of us knows what navData{c}.receiverTow
% is. More precisely we don't know which time system it belongs to.
% For the moment, I assume its just the first one,
% till somebody figures this out. Obviously this is wrong.


satSystems=fieldnames(obsData);
obsDataFirstSystem=getfield(obsData,satSystems{1});

timeSystem=inferSatSystem(satSystems(1));
wN=obsDataFirstSystem.channel(1).week;
tow=obsDataFirstSystem.receiverTow(c);

zeroTime=getZeroTime(timeSystem, settings.rnx.gpsRollovers); % zerotime includes GPS week number rollovers.

epochTime=seconds(tow)+days(wN*7)+zeroTime;

epochFlag=0;
clockOffset=NaN; %NaN if not applied ow supply
% {satSysId,datetime, epoch flag, clock offset}
timeC={timeSystem,epochTime,epochFlag,clockOffset};
sont=r3oh.sysObsNoTypes;
m{iM}=timeC;
iM=iM+1;
iMm=1;
m{iM}={};
meas=NaN;

for ii=1:length(sont)
    r3otn=sont(ii);
    for jj=1:r3otn.noObs
        r3oid=r3otn.obsCodes(jj);
        tm=r3oid.trackingMode;
        cb=r3oid.carrierBand;
        ot=r3oid.observationType;
        s=r3oid.system;
        fgiSignalRep=stna2fgiRep(r3oid);
        fgiSig=getfield(obsData,fgiSignalRep);
        for kk=1:length(fgiSig.channel)
            fgiChannel=fgiSig.channel(kk);
            p=fgiChannel.SvId.satId;
            r3sid=rinex3SatId(s,p);
            if ~r3sid.isValid()
                error('measurment satellite is not valid.')
            end

            % at this point, observation type
            % and the system must be consistent one to another
            % in fgi-gsrx, the same observation type is
            % generated for all the signals.
            try
                switch ot
                    case obsType.range
                        meas=fgiChannel.rawP(c);
                    case obsType.phase
                        if ~isnan(fgiChannel.accPhase(c))
                            currentPhaseCycles = fgiChannel.accPhase(c) / (2*pi);
                            
                            speed_light = 299792458;
                            lambda = speed_light / fgiChannel.carrierFreq;
    
                            initialPseudorange = fgiChannel.rawP(1);
                            initialPhaseCycles = fgiChannel.accPhase(1) / (2*pi);
                            
                            % This offset makes (Phase * Lambda) roughly equal to pseudorange
                            phaseOffset = (initialPseudorange / lambda) - initialPhaseCycles;
    
                            %phaseOffset = 0;  
                            meas = currentPhaseCycles + phaseOffset;
                        
                            % apply the phase corrections
                            phaseCorr = rinex3ObsHeader.phaseCorrectionTable(rinex3ObsId(tm,cb,ot,s));
                            if ~isnan(phaseCorr)
                                meas = meas + phaseCorr;
                            end
                        else
                            meas = NaN;
                        end

                    case obsType.snr
                        meas=fgiChannel.SNR(c);
                    case obsType.doppler
                        % FGI-GSRX writes doppler in meters,
                        % this converts it to Hz.
                        speed_light=299792458;
                        meas=fgiChannel.doppler(c)*...
                                fgiChannel.carrierFreq/speed_light;
                    case obsType.iono
                        meas=fgiChannel.ionoCorr(c);
                end
            catch ME
                if strcmp(ME.identifier,'MATLAB:badsubscript')
                    meas=NaN;
                else
                    rethrow(ME)
                end
            end
            
            r3oidCp=rinex3ObsId(tm,cb,ot,s);
            if ~r3oidCp.isValid()
                error('invalid measurement type.')
            end
            m{iM}{iMm}={r3sid,r3oidCp,meas};
            iMm=iMm+1;

        end
    end
end
end