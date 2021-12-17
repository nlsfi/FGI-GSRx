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
function codeReplica = gpsl1GeneratePrnCode(PRN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generates one GPS satellite code
%
% Inputs:
%   PRN         - PRN number for which gold codes will be generated.
%
% Outputs:
%   codeReplica - Generated code replica in chips for the given PRN number.  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% First, we have to make the code shift array. The code shift depends on the PRN number

% The vector g2s holds the appropriate shift of the g2 code to generate the C/A code (for example, satellite Vehicle #17 should use a G2 shift of g2s(17) = 469)
g2s = [  5,   6,   7,   8,  17,  18, 139, 140, 141, 251, 252, 254, 255, 256, 257, 258, 469, 470, 471, 472, ...
         473, 474, 509, 512, 513, 514, 515, 516, 859, 860, 861, 862];

% Take the right shift for the required PRN number 
g2shift = g2s(PRN);

% Initialize g1 register (of length 1023 chips) output to speed up the function 
g1_register = zeros(1, 1023);    

% Load shift register
register = -1*ones(1, 10);

% Generate all G1 signal chips based on the G1 feedback polynomial
for codeChip=1:1023
    g1_register(codeChip)       = register(10);
    saveBit     = register(3)*register(10);
    register(2:10)   = register(1:9);
    register(1)      = saveBit;
end

% Initialize g2 output to speed up the function
g2_register = zeros(1, 1023);

% Load shift register once again
register = -1*ones(1, 10);

% Generate all G2 signal chips based on the G2 feedback polynomial
for i=1:1023
    g2_register(i)       = register(10);
    saveBit     = register(2)*register(3)*register(6)*register(8)*register(9)*register(10);
    register(2:10)   = register(1:9);
    register(1)      = saveBit;
end

% Shift g2 code as mentioned in GPS ICD
g2_register = [g2_register(1023-g2shift+1 : 1023), g2_register(1 : 1023-g2shift)];

% Constitute sample C/A code by multiplying g1 and a2, as mentioned in GPS ICD
codeReplica = -(g1_register .* g2_register);

