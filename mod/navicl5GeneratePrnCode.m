%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2015-2021 Finnish Geospatial Research Institute FGI, National
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

function CAcode = navicl5GeneratePrnCode(PRN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generates one of the IRNSS L5 satellite C/A codes.
%
%   Inputs:
%       PRN         - PRN number of the sequence.
%
%   Outputs:
%       CAcode      - a vector containing the desired C/A code sequence
%                   (chips).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CAcode = zeros(1,1023);

%initial state for G1
G1 = ones(1:10);

%intial state for G2 depends on the PRN number
switch PRN
    case 1
        G2 = [1 1 1 0 0 1 0 1 1 1];        
    case 2
        G2 = [0 1 1 0 0 1 0 0 0 0];        
    case 3
        G2 = [0 0 1 0 1 1 0 0 0 1];        
    case 4
        G2 = [0 1 0 0 1 1 1 0 1 0];        
    case 5
        G2 = [0 0 0 0 1 1 0 1 1 1];        
    case 6
        G2 = [1 1 0 1 0 1 1 0 0 0];        
    case 7
        G2 = [0 0 1 0 1 0 0 0 0 0];        
end

%compute the CA code
for i = 1023:-1:1
    G1_out = G1(end);
    G2_out = G2(end);
    CAcode(i) = xor(G1_out,G2_out);
    
    newG1bit = xor(G1(3),G1(10));
    newG2bit = xor(xor(xor(xor(xor(G2(2),G2(3)),G2(6)),G2(8)),G2(9)),G2(10));
    
    G1 = [newG1bit G1(1:9)];
    G2 = [newG2bit G2(1:9)];
end
CAcode = CAcode(end:-1:1);
zeroIndices = find(CAcode(:)==0);
CAcode(zeroIndices)=-1;

