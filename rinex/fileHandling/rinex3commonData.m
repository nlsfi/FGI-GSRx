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
classdef (Abstract) rinex3commonData < handle
% RINEX3DATABASE Base class for RINEX data blocks (Obs & Nav)
%
% properties:
%   observations:cell
%   numSvs:double
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    properties
        numSvs = NaN;
        observations = {};
    end

    methods

        function clear(obj)
            obj.numSvs = NaN;
            obj.observations = {};
        end

        function set.numSvs(obj, i)
            if ~isa(i, 'double')
                error('%s:incorrectType', class(obj), ...
                      'numSvs must be double, not %s', class(i))
            else
                obj.numSvs = i;
            end
        end

        function set.observations(obj, i)
            if ~iscell(i)
                error('%s:incorrectType', class(obj), ...
                      'observations must be cell, not %s', class(i))
            else
                obj.observations = i;
            end
        end        
    end
    % end of methods

    methods (Static=true)
        function ssm=sortObs(m,r3h)
        % SORTOBSOUTER sorts m based on the satellite systems in r3oh.
        %
        % More specifically if
        % m={m1,m2,...mZ} where mi={A,B,D}
        %   A:rinex3SatId
        %   B:rinex3ObsId
        %   D:double
        % sortObs(m,r3oh) returns ssm as described below.
        % ssm=C1; C1={C21,C22,,..C2M} and C2i={C2i1,C2i2,...C2iNj}
        % where:
        %   M is the number satellite systems as defined in
        %   r3oh.sysObsNoTypes.
        %   Nj is the number of measurement (including missing ones)
        %   for a given satellite system.
        %   C2ik={A,B,D}
        %
        % C1 will follow thses conventions:
        %   - length(C1)=length(r3oh.sysObsNoTypes)
        %   - C2i only contains C2ik of the same satellite system
        %     defined in r3oh.sysObsNoTypes(i)
        %   - C2ik will follow the same order of observation types
        %     as defined in r3oh.sysObsNoTypes(i).obsCodes for each
        %     distinct satellite vehicle. e.g., if the header specifies
        %     observation codes C1C,L1C for GPS satellite system and
        %     G1,G4,G8,G32 are available in m, the corresponding C2i 
        %     will result in 4*2 cells each consecutive pair following
        %     the order first C1C, then L1C for each satellite vehicle,
        %     hence two cells for each satellite, in case a measurement
        %     is missing, C2i will create have an additional cell with
        %     NaN in the right order. Note that members of C2i are 
        %     not organized according to satellite number.
        %
        % m:cell  
        % r3oh:rinex3ObsHeader
        % sm:cell
        
        hSont=r3h.sysObsNoTypes;
        nHs=length(hSont);
        
        measLeft=m;
        sm=cell(1,nHs);
        ssm=cell(1,nHs);
        for ii=1:nHs
            hSys=hSont(ii).satellite.system;
            iSm=1;
            nml=length(measLeft);
            measLeftNdcs=ones(1,nml);    % 0:sorted already, 1:left
            for jj=1:nml
                if hSys==measLeft{jj}{1}.system
                    measLeftNdcs(jj)=0;
                    sm{ii}{iSm}=measLeft{jj};
                    iSm=iSm+1;
                end
            end
            ssm{ii}=rinex3ObsData.sortObsInner(sm{ii},hSont(ii));
            if any(measLeftNdcs)
                measLeft=measLeft(measLeftNdcs==1);
            else
                break
            end
        end

        end
        % end of function sortObs
        
        function ssm=sortObsInner(sm,sont)
        % SORTOBSINNER sorts cells within sm based on the order defined 
        % within sont.obsCodes. e.g, if sont.obsCodes defines 3
        % observations C1C,L1C,D1C for GPS L1 C/A, and sm is
        % {A1,A2,A3} where
        % Ai is {r3sidAi,r3oidAi,mAi};   for i=1,2,3
        % ssm will be:
        % {B1,B2,B3} where
        % Bj is {r3sidBj,r3oidBj,mBj};   for j=1,2,3
        % and r3oidB1=C1C,r3oidB2=L1C,r3oidB3=D1C.
        %
        % In case sm={A1,A2,...,AN} and sont.obsCodes=[obs1,...obsM]
        %   if N<M    =>    missing measurements are identified and 
        %                   new cells with NaN measurements are created.
        %   if N>M    =>    % TODO add this to validation, cause this 
        %                   must never happen.
        %
        % sm:cell
        %   cell of bunch of {rinex3SatId,rinex3ObsId,measurement}
        %   all belonging to the same satellite system.
        % sont: rinex33ObsTypeNum
        %   specifies the satellite system and the order based on which
        %   {rinex3SatId,rinex3ObsId,measurement} cells of sm are to be
        %   organized.
        % ssm:cell
        %   cell of bunch of {rinex3SatId,rinex3ObsId,measurement}
        %   but organized based on sont.obsCodes for each satellite
        %   prn after another.
        if ~isa(sont,'rinex3ObsTypeNum')
            error('rinex3ObsData:badType',...
                'input must be of type rinex3ObsTypeNum, but not %s',...
                class(sont))
        elseif length(sont)>1
            error('sont can not be an array of rinex3ObsTypeNum objects.')
        end
        iSsm=1;
        ssm={};
        nSm=length(sm);
        if nSm==0
            return
        end
        
        nRefOc=sont.noObs;
        obsCodesC=cell(1,nRefOc);
        for i=1:nRefOc
            obsCodesC{i}=sont.obsCodes(i).as3letter();
        end
        
        
        ndcsLeft=ones(1,nSm);     %0:,1:left
        smLeft=sm(ndcsLeft==1);
        while any(ndcsLeft)
            % take the first element of the cell and find all the cells
            % with the same prn number
            r3sid=smLeft{1}{1};
            r3oid=smLeft{1}{2};
            v=smLeft{1}{3};
            p=r3sid.p;
            ndcsSameP=[1];
            %ocSameP=[];
            ocSamePC={};
            vSameP=[];
            ocSameP(1)=r3oid;
            ocSamePC{1}=r3oid.as3letter();
            vSameP(1)=v;
            for i=2:length(smLeft)
                if smLeft{i}{1}.p==p
                    ndcsSameP=[ndcsSameP,i];
                end
            end
            % this block sorts the cells with the same prn based on the
            % sont.obsCodes
            nOc=length(ndcsSameP);   % guaranteed to be all unique?
            for i=2:nOc
                ocSamePC{i}=smLeft{ndcsSameP(i)}{2}.as3letter();
                ocSameP(i)=smLeft{ndcsSameP(i)}{2};
                vSameP(i)=smLeft{ndcsSameP(i)}{3};
            end 
            [~,locb]=ismember(ocSamePC,obsCodesC);
            [locbS,sortNdcs]=sort(locb);
            for i=1:nRefOc
                [a,b]=ismember(i,locbS);
                if a
                    % observation exists, reconstruct with 4 parameters
                    j=sortNdcs(b);
                    ssm{iSsm}={rinex3SatId(sont.satellite.system,p),...
                            ocSameP(j),vSameP(j)};
                    %ssm{iSsm}=
                else
                    % Fill with NaN/Empty if measurement is missing
                    ssm{iSsm}={rinex3SatId(sont.satellite.system,p),...
                                sont.obsCodes(i),...
                                NaN};
                end
                iSsm=iSsm+1;
            end
            % at this pointnOc measurements w/o NaN values are in ssm
            ndcsLeft(ndcsSameP)=0;           
            smLeft=smLeft(ndcsLeft==1);
            ndcsLeft=ndcsLeft(ndcsLeft==1);
        end
        end
            % end of function sortObsInner()
        end
    % end of methods block
end
