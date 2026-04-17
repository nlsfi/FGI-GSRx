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
function fs=inferSatSystem(c)
% INFERSATSYSTEMS 
% returns rinex3SatId object corresponding to a char vector description of
% GNSS signal frequnecy bands as defined within FGI-GSRx, e.g:
% {'gpsl1'}=> rinex3SatId(satSysId.systemGPS).
%
% returns rinex3SatId(satSysId.systemMixed) if c is
% multitude of signals belonging to different satellite 
% systems, e.g: {'gpsl2cm','glol1'}
%
% Inputs:
%   c:cell          - char vector for the satsystem(s) name
% Outputs:  
%   fs:satSysId     - rinex3SatId object
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~iscellstr(c)
    error('input must be a cell array of character inputs.')
end

if isempty(c)
    error('input seems to be empty.')
end

bGps=any(ismember(c,{'gpsl1','gpsl1c','gpsl2cm','gpsl5I'}));
bGal=any(ismember(c,...
        {'gale1b','gale5','gale5bI','gale5bQ','gale5aI','gale5aQ'}));
bGlo=any(ismember(c,{'glol1'}));
bBei=any(ismember(c,{'beib1'}));
bIrn=any(ismember(c,{'navicl5'}));
b=[bGps,bGal,bGlo,bBei,bIrn];
k=find(b);
if length(k)>1
    fs=rinex3SatId(satSysId.systemMixed);
elseif length(k)==1
    switch k
        case 1
            fs=rinex3SatId(satSysId.systemGPS);
        case 2
            fs=rinex3SatId(satSysId.systemGalileo);
        case 3
            fs=rinex3SatId(satSysId.systemGLONASS);
        case 4
            fs=rinex3SatId(satSysId.systemBDS);
        case 5
            fs=rinex3SatId(satSysId.systemIRNSS);
    end
else    
    error('writeRinex3Obs:NotImplemented',...
        'add to the supported satellite system.')
end
end