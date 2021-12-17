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
function status = gpsl1NavParityCheck(tC, index, wordNr)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function is called to compute and status the parity bits on GPS word.
% Based on the flowchart in Figure 2-10 in the 2nd Edition of the GPS-SPS
% Signal Spec.
%
% Inputs:
%   tC          - Data for one tracking channel
%   index       - Index for start of data bits
%   wordNr      - Word number within data
%
% Outputs: 
%   status      - the result of the parity check, which equals EITHER 
%                   +1: parity check has passed and bits #1-24
%                       of the current word have the correct polarity,
%                   -1: parity check has passed and bits #1-24 of the 
%                       current word must be inverted,
%                    0: parity check has failed.   
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extract data bits
bits = tC.I_P(index-40 : index + 20 * 1500 -1)';

% Combine the 20 values of each bit 
bits = reshape(bits, 20, (size(bits, 1) / 20));
bits = sum(bits);

% Now threshold and make it -1 and +1 
bits(bits > 0)  = 1;
bits(bits <= 0) = -1;

nDataBits = bits(1 + (wordNr - 1)*30:2 + wordNr * 30);

% Now to determine if the data bits should be inverted
if (nDataBits(2) ~= 1)
    nDataBits(3:26)= -1 .* nDataBits(3:26); %here data bits are inverted
end

% Calculate 6 parity bits following the GPS ICD
calcParity(1) = nDataBits(1)  * nDataBits(3)  * nDataBits(4)  * nDataBits(5)  * nDataBits(7)  * ...
                nDataBits(8)  * nDataBits(12) * nDataBits(13) * nDataBits(14) * nDataBits(15) * ...
                nDataBits(16) * nDataBits(19) * nDataBits(20) * nDataBits(22) * nDataBits(25);

calcParity(2) = nDataBits(2)  * nDataBits(4)  * nDataBits(5)  * nDataBits(6)  * nDataBits(8)  * ...
                nDataBits(9)  * nDataBits(13) * nDataBits(14) * nDataBits(15) * nDataBits(16) * ...
                nDataBits(17) * nDataBits(20) * nDataBits(21) * nDataBits(23) * nDataBits(26);

calcParity(3) = nDataBits(1)  * nDataBits(3)  * nDataBits(5)  * nDataBits(6)  * nDataBits(7)  * ...
                nDataBits(9)  * nDataBits(10) * nDataBits(14) * nDataBits(15) * nDataBits(16) * ...
                nDataBits(17) * nDataBits(18) * nDataBits(21) * nDataBits(22) * nDataBits(24);

calcParity(4) = nDataBits(2)  * nDataBits(4)  * nDataBits(6)  * nDataBits(7)  * nDataBits(8)  * ...
                nDataBits(10) * nDataBits(11) * nDataBits(15) * nDataBits(16) * nDataBits(17) * ...
                nDataBits(18) * nDataBits(19) * nDataBits(22) * nDataBits(23) * nDataBits(25);

calcParity(5) = nDataBits(2)  * nDataBits(3)  * nDataBits(5)  * nDataBits(7)  * nDataBits(8)  * ...
                nDataBits(9)  * nDataBits(11) * nDataBits(12) * nDataBits(16) * nDataBits(17) * ...
                nDataBits(18) * nDataBits(19) * nDataBits(20) * nDataBits(23) * nDataBits(24) * ...
                nDataBits(26);

calcParity(6) = nDataBits(1)  * nDataBits(5)  * nDataBits(7)  * nDataBits(8)  * nDataBits(10) * ...
                nDataBits(11) * nDataBits(12) * nDataBits(13) * nDataBits(15) * nDataBits(17) * ...
                nDataBits(21) * nDataBits(24) * nDataBits(25) * nDataBits(26);

% Verify if the value of calculated parity is equal to the value of 
% received parity, and that the sum of the bits in both is equal to 6. 
% Otherwise, mark the parity check as failed.
if (sum(calcParity - nDataBits(27:32)) == 0)    
    % Parity check is successful. The resulting status will be either
    % -1 or +1 depending on if the data bits should be inverted or not.
    status = -1 * nDataBits(2);    
else
    % Otherwise, mark parity check as failed
    status = 0;
end
