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
function s=stna2fgiRep(r3oid)
% stna2FGI returns a cell of a char vector
% 
% 'gpsl1','gpsl2cm','
if ~isa(r3oid,'rinex3ObsId')
    error('input must be of type rinex3ObsId.')
end

switch r3oid.system
    case satSysId.systemGPS
        switch r3oid.carrierBand
            case carrierBand.L1
                switch r3oid.trackingMode
                    case trackingMode.CA
                        s = 'gpsl1';      % L1 C/A
                    case {trackingMode.DP, trackingMode.IQ}
                        s = 'gpsl1c';     % L1C
                end
            case carrierBand.L2
                s='gpsl2cm';
            case carrierBand.L5
                s='gpsl5I';
            otherwise
                error('alter the implementation.')
        end
    case satSysId.systemGalileo
        switch r3oid.carrierBand
            case carrierBand.E1
                s='gale1b';
            case carrierBand.E5
                s='gale5';
            case carrierBand.E5a
                switch r3oid.trackingMode
                    case trackingMode.I
                        s='gale5aI';
                    case trackingMode.Q
                        s='gale5aQ';
                end
            case carrierBand.E5b
                switch r3oid.trackingMode
                    case trackingMode.I
                        s='gale5bI';
                    case trackingMode.Q
                        s='gale5bQ';
                end
        end
    otherwise
        error('alter the implementation.')
end
end