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
function [ decodedBits ] = viterbiDecoding( encodedSymbols,trellis,tblen )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Convolutionally decodes binary data using the Viterbi algorithms
%
%   Inputs:
%       encodedSymbols  - encoded symbols after de-interleaving
%       trellis         - trellis form of Galileo convolutional code generator polynomials
%       tblen           - traceback length
%   Outputs:
%        decodedBits    - Viterbi decoded bits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
blockSize = tblen; 

% Initialize the accumulated error metric for all the states, so that the
% algorithm starts from state 1 (corresponding to six zeros) for the first block
AEM = Inf*ones(64,1); 
AEM(1) = 0;

outputBins1 = str2num(cell2mat(trellis.outputsBin(:,1)));
outputBins2 = str2num(cell2mat(trellis.outputsBin(:,2)));

for blockId = 1:length(encodedSymbols)/blockSize
    % Extract block of 40 encoded symbols
    rxBlock = encodedSymbols(blockSize*(blockId-1)+1:blockSize*blockId);
    
    % Initial state at the beginning of each 40 symbols block
    initialState = find(AEM==min(AEM));
    
    currentStates = initialState;
    predecessors = zeros(64,blockSize/2);
    
    for t = 1:blockSize/2
        rxSymbol = rxBlock(2*(t-1)+1:2*t); % 2 bits
        previousAEM = AEM;
        auxMatrix = Inf*ones(64,64);
        
        for stateId = currentStates'
            % For input bit = 0
            d0 = sum(abs(rxSymbol-outputBins1(stateId,:))); % Hamming distance
            auxMatrix(trellis.nextStatesDec(stateId,1)+1,stateId) = d0+previousAEM(stateId);
            % For input bit = 1
            d1 = sum(abs(rxSymbol-outputBins2(stateId,:))); % Hamming distance
            auxMatrix(trellis.nextStatesDec(stateId,2)+1,stateId) = d1+previousAEM(stateId);
        end
        [AEM,indices] = min(auxMatrix,[],2);
        % List of states reached at current time step
        currentStates = find(AEM~=Inf);
        % Update list of predecessors for every state
        predecessors(find(AEM~=Inf),t) = indices(find(AEM~=Inf));
    end
    
    % Retrieve the sequence of states that form the most likely path
    minAEM = find(AEM==min(AEM));
    if blockId ~= length(encodedSymbols)/blockSize
        statesSequence(blockSize/2+1) = minAEM(1);
    else
        statesSequence(blockSize/2+1) = 1;
    end
    for t = 1:blockSize/2
        step = (blockSize/2-t)+1;
        statesSequence(step) = predecessors(statesSequence(step+1),step);
    end
    % Find the transmitted bits corresponding to state transitions forming the most likely path
    for s = 1:blockSize/2
        
        successiveStates = statesSequence(s:s+1);
        if trellis.nextStatesDec(successiveStates(1),1)+1 == successiveStates(2)
            inputBits(s) = 0;
        elseif trellis.nextStatesDec(successiveStates(1),2)+1 == successiveStates(2)
            inputBits(s) = 1;
        end
    end
   decodedBits((blockId-1)*blockSize/2+1:blockId*blockSize/2) = inputBits; 
end

end
