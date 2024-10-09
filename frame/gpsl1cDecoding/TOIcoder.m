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
function output_bits = TOIcoder(TOInumber)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function gives an encoded GPS L1C TOI sequence for a given time-of-interval number
%
% Inputs:
%   TOInumber   - Time of interval (TOI)
%
% Outputs:
%   output_bits - 52 bit long BCH encoded TOI sequence
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
bits = logical(cast(dec2bin(TOInumber,9),"uint8")-48);
MSB = bits(1);
LSB = bits(2:end);

% Generator polynomial 763 (octal) with last bit dropped as it is not needed
genpoly = logical([1,1,1,1,1,0,0,1]);

% Initialize LSFR bits
LSFRbits = zeros(1,51);
n = LSB;

% Loop LFSR algorithm
for i = 1:51
    LSFRbits(i) = n(1);             % Pick lowest (highest in ICD) index from the state to output
    nend = mod(sum(genpoly.*n),2);  % Calculate new value to be added to state
    n = circshift(n,-1);            % Circshift the state; value of the lowest index is shifted to highest index
    n(end) = nend;                  % Replace old lowest and now highest index with the new value
end
output_bits = [MSB, bitxor(LSFRbits,MSB)];

% Represent zero bits with value -1
zeroIndices = output_bits == 0;
output_bits(zeroIndices) = -1;