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
classdef trackingMode
    % TRACKINGMODE tracking modes as defined within rinex3.xx protocol.
    % The comment lines in front of each member declaration,
    % specify the correspondance.

    enumeration
        CA      % GPS{L1,L2},GLONASS{G1,G2},
                % Galileo{E1(no data),E6(no data)}
                % SBAS{L1},QZSS{L1}
                % IRNSS{L5(C RS(P)),S(C RS(P))}

        D       % GPS{L1C(D),L2(L2CM)}
                % QZSS{L2C(M)}

        DD      % GPS{L1(C/A)+(P2-P1)},
                % QZSS{L5(L5D)},
                % BDS{B1(Data),B2b(Data),B2(Data)}

        P       % GPS{L1C(P),L2(L2CL)},
                % QZSS{L1(L1CP),L2(L2CL),L6(L6P)}

        DP      % GPS{L1C(D+P),L2(L2C(M+L))}
                % GLONASS{G1a(L1OCd+L1OCp),G2a(L2CSI+L2OCp)}
                % Galileo{E1(B+C),E6(B+C)},
                % QZSS{(L1C(D+P),L2(L2C(M+L))),L6(L6(D+P))},
                % BDS{B1(Data+pilot),B2a(Data+pilot),B2(Data+Pilot)},
                % IRNSS{L5(B+C),S(B+C)}

        PP      % GPS{L1(P AS off),L2(P AS off)},
                % GLONASS{G1(P),G2(P)},
                % QZSS{L5(P)}
                % BDS{B1(pilot),B2a(pilot),B2b(pilot),B2(pilot)}

        Z       % GPS{L1(Z-tracking),L2(Z-tracking)}

        ZZ      % Galileo{E1(A+B+C),E6(A+B+C)},
                % QZSS{L1(L1S/L1-SAIF),L5(L5(D+P)),L6(L6(D+E))},
                % BDS{B2b(data+pilot)}

        Y       % GPS{L1(Y),L2(Y)}

        M       % GPS{L1(M),L2(M)}

        N       % GPS{L1(codeless),L2(codeless)},
                % BDS{B1(codeless)}

        I       % GPS{L5(I)},GLONASS{G3(I)},Galileo{E5a(I F/NAV OS),
                % E5b(I I/NAV) OS,E5(I)},SBAS{L5(I)},QZSS{L5(I)},
                % BDS{B1-2(I),B2b(I),B3[I]}

        Q       % GPS{L5(Q)},GLONASS{G3(Q)},Galileo{E5a(Q),E5b(Q),
                % E5(Q)},QZSS{L5(Q)},BDS{N1-2(Q),B2b(Q),B3(Q)}

        IQ      % GPS{L5(I+Q)},GLONASS{G3(I+Q)},Galileo{E5a(I+Q),E5b(I+Q),
                % E5(I+Q)},QZSS{L5(I+Q)},BDS{N1-2(I+Q),B2b(I+Q),B3(I+Q)},
                % SBAS{L5(I+Q)}

        A       % GLONASS{G1a(L1oCd),G2a(L2CSI)},
                % Galileo{E1(A PRS),E6(A PRS)},
                % BDS{B1(B1A),B3(B3A)},
                % IRNSS{L5(A SPS),S(A SPS)}

        B       % GLONASS{G2a(L2OCp)},
                % Galileo{E1(B I/NAV),E6(B C/NAV)},
                % IRNSS{L5(B RS (D)),S(B RS( D))}
        
        unknown
    end
end
