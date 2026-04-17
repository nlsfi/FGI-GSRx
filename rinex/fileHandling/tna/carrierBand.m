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
classdef carrierBand
    % CARRIERBAND carrier frequency band
    enumeration
        X       % 0 -- all

        L1      % 1 -- GPS(L1),SBAS(L1),QZSS(L1),
        G1      % 1 -- GLONASS(G1)
        E1      % 1 -- Galileo(E1)
        B1      % 1 -- BDS B1

        L2      % 2 -- GPS(L2),QZSS(L2)
        G2      % 2 -- GLONASS(G2)
        B12     % 2 -- BDS(B1-2)

        G3      % 3 -- GLONASS(G3)

        G1a     % 4 -- GLONASS(G1a)

        L5      % 5 -- GPS(L5),QZSS(L5),SBAS(L5),IRNSS(L5)
        E5a     % 5 -- Galileo(E5a)
        B2a     % 5 -- BDS(B2a)

        G2a     % 6 -- GLONASS(G2a)
        E6      % 6 -- Galileo(E6)
        L6      % 6 -- QZSS(L6)
        B3      % 6 -- BDS(B3)

        E5b     % 7 -- Galileo(E5b)
        B2b     % 7 -- BDS(B2b)

        E5      % 8 -- Galileo(E5)
        B2      % 8 -- BDS(B2)

        S       % 9 -- IRNSS(S)
        
        unknown
    end
end
