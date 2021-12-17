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
function tR = bitSync(tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bit sync function for GPS and GLONASS signal
%
% Inputs:
%   tR             - Results from signal tracking for one signals
%   ch             - Channel index
%
% Outputs:
%   tR             - Results from signal tracking for one signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set local variables
trackChannelData = tR.channel(ch);
loopCnt = trackChannelData.loopCnt;
if (strcmp(tR.signal,'glol1')) 
    bitLength = trackChannelData.meanderBitDuration;
else
    bitLength = trackChannelData.bitDuration;
end
bitSyncConfidenceLevel = trackChannelData.bitSyncConfidenceLevel;

if(trackChannelData.bitSync == 1)
    return; % Nothing to do yet
end

% Consider a time window of 1000 ms
minStartInd = max([loopCnt-1000 1]);

% Calculate normalised phase difference between pair of samples next to each other
phaseDiff = trackChannelData.I_P(minStartInd+1:loopCnt)-trackChannelData.I_P(minStartInd:loopCnt-1);
normalizedPhaseDiff = phaseDiff/max(phaseDiff);

% Find indexes for values large enough
phaseChangeIndices = find(abs(normalizedPhaseDiff)>0.5);

if isempty(phaseChangeIndices)==0
    for bitInd=1:length(phaseChangeIndices)
        bitIndCandidate = phaseChangeIndices(bitInd);
        confidenceLevel = find(mod(abs(phaseChangeIndices(1:end)-bitIndCandidate),bitLength)==0);
        if (length(confidenceLevel)>=bitSyncConfidenceLevel)
            trackChannelData.bitBoundaryIndex=bitIndCandidate+1;
            trackChannelData.bitBoundaryIndex=mod(trackChannelData.bitBoundaryIndex,bitLength);
            if trackChannelData.bitBoundaryIndex==0
                trackChannelData.bitBoundaryIndex=bitLength;
            end
            % Check whether bitSync is really successfull by looking at
            % the I_P correlation values: they should have at least same
            % sign for one whole bit
            if mod(sum(sign(trackChannelData.I_P((loopCnt+trackChannelData.bitBoundaryIndex)-2*bitLength:(loopCnt+trackChannelData.bitBoundaryIndex)-bitLength-1))),bitLength)==0
                if  trackChannelData.bitSync == 0
                    disp(['   Bit sync for ', tR.signal, ' prn ', ...
                        int2str(trackChannelData.SvId.satId),' found at ',int2str(loopCnt), ' with index ', int2str(trackChannelData.bitBoundaryIndex)]);
                end
                trackChannelData.bitSync = 1;
                trackChannelData.bitBoundaryIndex=trackChannelData.bitBoundaryIndex;
                break;
            end
        end
    end
end

% Copy updated local variables
tR.channel(ch) = trackChannelData;
    
