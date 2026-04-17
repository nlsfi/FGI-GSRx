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
function sontSorted=getSysObsNoTypes(obsData,ot)
% GETSYSOBSNOTYPES
% returns an array of rinex3ObsTypeNum objects corresponding to the observation types
% obsData:struct
% ot:obsType
%   array of desired observation types.'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%55

satSystems=fieldnames(obsData);
if isempty(satSystems)
    error('obsData seems to be empty.')
else
    sontSorted=[];
    noObs=length(ot);

    for i=1:length(satSystems)

        r3oid=[];
        if strcmp(satSystems{i},'gpsl1')

            ssId=satSysId.systemGPS;
            tm=trackingMode.CA;
            cb=carrierBand.L1;

        elseif strcmp(satSystems{i},'gpsl1c')
            ssId=satSysId.systemGPS;
            tm=trackingMode.DP;
            cb=carrierBand.L1;

        elseif strcmp(satSystems{i},'gpsl2cm')
            ssId=satSysId.systemGPS;
            tm=trackingMode.D;
            cb=carrierBand.L2;

        elseif strcmp(satSystems{i},'gpsl5I')
            ssId=satSysId.systemGPS;
            tm=trackingMode.I;
            cb=carrierBand.L5;
            
        elseif strcmp(satSystems{i},'gale1b')
            ssId=satSysId.systemGalileo;
            tm=trackingMode.B;
            cb=carrierBand.E1;

        elseif strcmp(satSystems{i},'gale5')
            ssId=satSysId.systemGalileo;
            tm=trackingMode.IQ;
            cb=carrierBand.E5;

        elseif strcmp(satSystems{i},'gale5bI')
            ssId=satSysId.systemGalileo;
            tm=trackingMode.I;
            cb=carrierBand.E5b;

        elseif strcmp(satSystems{i},'gale5bQ')
            ssId=satSysId.systemGalileo;
            tm=trackingMode.Q;
            cb=carrierBand.E5b;

        elseif strcmp(satSystems{i},'gale5aI')
            ssId=satSysId.systemGalileo;
            tm=trackingMode.I;
            cb=carrierBand.E5a;
            
        elseif strcmp(satSystems{i},'gale5aQ')
            ssId=satSysId.systemGalileo;
            tm=trackingMode.Q;
            cb=carrierBand.E5a;
        
            
        else
            error('writeRinex3Obs:notImplemented',...
                'alter the implementation,add support.')
        end

        for j=1:noObs
            r3oid=[r3oid,rinex3ObsId(tm,cb,ot(j),ssId)];
        end



        % sort it
        similarSysFound=false;
        lss=length(sontSorted);
        if lss>=1
            for jj=1:lss
                if sontSorted(jj).satellite.system==ssId
                    % append sontSorted(jj)
                    sont=rinex3ObsTypeNum(rinex3SatId(ssId),noObs,r3oid);
                    sontSorted(jj).appendObsTypes(sont);
                    similarSysFound=true;
                    break
                end
            end
        end
        if ~similarSysFound
            sontSorted=[sontSorted,...
                rinex3ObsTypeNum(rinex3SatId(ssId),noObs,r3oid)];
        end
    end
end
end