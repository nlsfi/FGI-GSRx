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
function codeReplica = beib1GeneratePrnCode(PRN)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generates one BeiDou satellite code
%
% Inputs:
%   PRN         - PRN number for code to generated.
%
% Outputs:
%   codeReplica - Generated code replica (chips).  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Generate G1 code 
g1 = zeros(1, 2046); % Initialize g1 output to speed up the function
reg = -1*[-1 1 -1 1 -1 1 -1 1 -1 1 -1]; % Load shift register

% Generate all G1 signal chips based on the G1 feedback polynomial
for i=1:2046
    g1(i)       = reg(11);
    saveBit     = reg(1)*reg(7)*reg(8)*reg(9)*reg(10)*reg(11);
    reg(2:11)   = reg(1:10);
    reg(1)      = saveBit;
end

% Generate G2 code 
g2 = zeros(1, 2046); % Initialize g2 output to speed up the function
reg2 = -1*[-1 1 -1 1 -1 1 -1 1 -1 1 -1]; % Load shift register
    
% Generate all G2 signal chips based on the G2 feedback polynomial 
for i=1:2046
    if PRN == 1
        g2(i) = reg2(1)*reg2(3);
    elseif PRN == 2
        g2(i) = reg2(1)*reg2(4);
    elseif PRN == 3 
        g2(i) = reg2(1)*reg2(5);
    elseif PRN == 4 
        g2(i) = reg2(1)*reg2(6);
    elseif PRN == 5 
        g2(i) = reg2(1)*reg2(8);
    elseif PRN == 6  
        g2(i) = reg2(1)*reg2(9);
    elseif PRN == 7 
        g2(i) = reg2(1)*reg2(10);
    elseif PRN == 8 
        g2(i) = reg2(1)*reg2(11);
    elseif PRN == 9 
        g2(i) = reg2(2)*reg2(7);
    elseif PRN == 10 
        g2(i) = reg2(3)*reg2(4);
    elseif PRN == 11 
        g2(i) = reg2(3)*reg2(5);
    elseif PRN == 12 
        g2(i) = reg2(3)*reg2(6);
    elseif PRN == 13 
        g2(i) = reg2(3)*reg2(8);
    elseif PRN == 14 
        g2(i) = reg2(3)*reg2(9);
    elseif PRN == 15 
        g2(i) = reg2(3)*reg2(10);
    elseif PRN == 16 
        g2(i) = reg2(3)*reg2(11);
    elseif PRN == 17 
        g2(i) = reg2(4)*reg2(5);
    elseif PRN == 18 
        g2(i) = reg2(4)*reg2(6);
    elseif PRN == 19 
        g2(i) = reg2(4)*reg2(8);
    elseif PRN == 20 
        g2(i) = reg2(4)*reg2(9);
    elseif PRN == 21 
        g2(i) = reg2(4)*reg2(10);
    elseif PRN == 22 
        g2(i) = reg2(4)*reg2(11);
    elseif PRN == 23 
        g2(i) = reg2(5)*reg2(6);
    elseif PRN == 24 
        g2(i) = reg2(5)*reg2(8);
    elseif PRN == 25 
        g2(i) = reg2(5)*reg2(9);
    elseif PRN == 26 
        g2(i) = reg2(5)*reg2(10);
    elseif PRN == 27 
        g2(i) = reg2(5)*reg2(11);
    elseif PRN == 28 
        g2(i) = reg2(6)*reg2(8);
    elseif PRN == 29 
        g2(i) = reg2(6)*reg2(9);
    elseif PRN == 30 
        g2(i) = reg2(6)*reg2(10);
    elseif PRN == 31 
        g2(i) = reg2(6)*reg2(11);
    elseif PRN == 32 
        g2(i) = reg2(8)*reg2(9);
    elseif PRN == 33 
        g2(i) = reg2(8)*reg2(10);
    elseif PRN == 34 
        g2(i) = reg2(8)*reg2(11);
    elseif PRN == 35 
        g2(i) = reg2(9)*reg2(10);
    elseif PRN == 36 
        g2(i) = reg2(9)*reg2(11);
    elseif PRN == 37 
        g2(i) = reg2(10)*reg2(11);
    end
    saveBit = reg2(1)*reg2(2)*reg2(3)*reg2(4)*reg2(5)*reg2(8)*reg2(9)*reg2(11);
    reg2(2:11) = reg2(1:10);
    reg2(1) = saveBit;
end
    codeReplica = -(g1 .* g2); % Form single sample code by multiplying G1 and G2
end