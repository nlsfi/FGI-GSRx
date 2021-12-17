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
function [ trellis ] = polyToTrellis(L,signal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Converts Galileo convolutional code generator polynomials into trellis form.
%
%   Input:
%   L          - constraint length 
%   signal     - processed GNSS signal
%
%   Output:
%   trellis    - Output structure with the following fields:
%               nextStatesBin - State transition table for the trellis (state index in binary format)
%               nextStatesDec - State transition table for the trellis (state index in decimal format)
%               outputsBin    - Table of output values for the trellis (in binary format)
%               outputsDec    - Table of output values for the trellis (in decimal format)
%     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

k = 1; % Input: one bit at the time

% Possible states 
statesBin = (dec2bin(0:(2^(L-1))-1)-'0');

% Possible inputs
inputs = (dec2bin(0:(2^k)-1)-'0');

numPossibleStates = 2^(L-1);
numPossibleInputs = 2^k;

% Build the state transition table and the outputs table
nextStatesBin = cell(numPossibleStates,2^k);
nextStatesDec = zeros(numPossibleStates,2^k);
outputsBin = cell(numPossibleStates,2^k);
outputsDec = zeros(numPossibleStates,2^k);
for s = 1:numPossibleStates
    for in = 1:numPossibleInputs
        nextState = [inputs(in) statesBin(s,1:end-k)];
        nextStatesBin{s,in} = int2str(nextState);
        nextStatesDec(s,in) = bin2dec(nextStatesBin{s,in});
        cells = [inputs(in) statesBin(s,:)];
        outputs = convolutionalEncoding(cells,signal);
        outputsBin{s,in} = int2str(outputs);
        outputsDec(s,in) = bin2dec(outputsBin(s,in));
        
    end
end
trellis.nextStatesBin = nextStatesBin;
trellis.nextStatesDec = nextStatesDec;
trellis.outputsBin = outputsBin;
trellis.outputsDec = outputsDec;
end