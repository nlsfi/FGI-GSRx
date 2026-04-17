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
function cmps(obj,fileId,r3oh)
% RINEX3OBSDATA.CMPS
% cmps(fileId,r3oh) writes a rinex 3.04 data record block
% on a file pointed to by fileId.
% fileId:double
%   file identifier
% r3oh:rinex3ObsHeader


if ~obj.isValid(r3oh)
    error('rinex3ObsData:invalid',...
        'the contents of this block does not qualify.')
end


line={'>'};
line=strcat(line,{obj.writeEpochTime()});
line=strcat(line,{repmat(' ',1,2)});
line=strcat(line,{sprintf('%1u',obj.epochFlag)});
line=strcat(line,{sprintf('%3u',obj.numSvs)});
line=strcat(line,{repmat(' ',1,6)});
if r3oh.clckOffsetAppl
    if isnan(obj.clckOffset)
        line=strcat(line,{repmat(' ',1,15)});
    else
        line=strcat(line,{sprintf('%15.12f',obj.clckOffset)});
    end
end
line=strcat(line,{'\n'});
fprintf(fileId,line{1});

% same order as the header
% at this point it must have been taken care of
% observations must be oragnized so that the
% the order of the header.sysObsNoTypes 
% in terms of the constellation is repsected.
% I do not check that here.

if (obj.epochFlag==0 || obj.epochFlag==1)
    n_system=length(r3oh.sysObsNoTypes);
    for ii=1:n_system
        mPerSys=obj.observations{ii};
        nObsPerSat=r3oh.sysObsNoTypes(ii).noObs;
        for jj=1:length(mPerSys)/nObsPerSat
            r3sid=mPerSys{(jj-1)*nObsPerSat+1}{1};
            line={sprintf('%c%02u',...
                          r3sid.aschar(),...
                          r3sid.p)};
            for kk=1:nObsPerSat
                v=mPerSys{(jj-1)*nObsPerSat+kk}{3};
                if ~isnan(v)
                    line=strcat(line,{sprintf('%14.3f',v)});
                else
                    line=strcat(line,{repmat(' ',1,14)});
                end

                % TODO
                line=strcat(line,{' '});    %LLI
                line=strcat(line,{' '});    %SSI
            end
            line=strcat(line,{'\n'});
            fprintf(fileId,line{1});
        end
    end
end
end
