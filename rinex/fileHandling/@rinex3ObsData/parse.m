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
function parse(obj,fileId,r3oh)
% RINEX3OBSDATA.PARSE
% reads a rinex 3.04 data record block from a file pointed to by fileId.
% Currently not in use.

if ~r3oh.isValid()
    error('header is not valid.')
end

line='';
% first line
line=fgetl(fileId);
line=strip(line,'right');
if line(1)~='>'
    error(['bad epoch line: >',line,'<'])
end
obj.epochFlag=sscanf(line(32),'%u');

obj.parseEpochTime(line);

obj.numSvs=sscanf(line(33:35),'%u');
if length(line)>41
    obj.clckOffset=sscanf(line(42:56),'%f');
end

if ismember(obj.epochFlag,[0,1,6])
    hSont=r3oh.sysObsNoTypes;
    nHs=length(hSont);
    m=cell(1,nHs);
    counters=ones(1,nHs);

    for ii=1:obj.numSvs
        line=fgetl(fileId);
        
        r3sid=rinex3SatId();
        r3sid.fromchar(line(1));
        r3sid.p=sscanf(line(2:3),'%u');
        
        % find the system from header
        for jj=1:nHs
            if hSont(jj).satellite.system==r3sid.system
                break
            end
        end

        nOt=hSont(jj).noObs;
        for kk=1:nOt
            % column
            col=3+(kk-1)*16+1;
            
            oC=hSont(jj).obsCodes(kk);
            
            % measurements could be missing from end
            % of the line or in the middle.
            try
                [v,nRead]=sscanf(line(col:col+13),'%f');
                if nRead==0
                    v=NaN;
                end
            catch ME
                switch ME.identifier
                    case 'MATLAB:badsubscript'
                        v=NaN;
                    otherwise
                        rethrow(ME)
                end
            end
            %TODO this copy might be problematic
            m{jj}{counters(jj)}={r3sid,oC,v};
            counters(jj)=counters(jj)+1;
        end
    end
end
obj.observations=m;
end
