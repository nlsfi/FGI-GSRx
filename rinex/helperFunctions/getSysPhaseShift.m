
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
function ssps=getSysPhaseShift(sont)
% GETSYSPHASESHIFT
% This function generates the system specific phase shift information for the observation types defined in the input.
% sont:rinex3ObsTypeNum

if ~isa(sont,'rinex3ObsTypeNum')
    error('wrong input type.')
end
count=1;
for i=1:length(sont)
    for j=1:sont(i).noObs
        if sont(i).obsCodes(j).observationType==obsType.phase
            
            % because FGI treats all of them the same way
            sat=rinex3SatId(sont(i).obsCodes(j).system);
            %correction=getPhaseCorrection(sont(i).obsCodes(j));
            correction=...
                rinex3ObsHeader.phaseCorrectionTable(sont(i).obsCodes(j));
            sps(count)=rinex3PhaseShift(sat,sont(i).obsCodes(j),correction);
            count=count+1;
        end
    end
end
% this block adds reference signals according to tableA.23
% NB. phase corrections are applied elsewhere separately
sats=[sont.satellite];
systems=[sats.system];
ssps=rinex3ObsHeader.sortPhaseShift(sps,systems);

end