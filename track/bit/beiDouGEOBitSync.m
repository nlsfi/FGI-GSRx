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
function trackChannelData = beiDouGEOBitSync(trackChannelData,loopCnt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bit sync function for Beidou GEO
%
%
%   Inputs:
%       trackChannelData - track data for one channel
%
%   Outputs:
%       trackChannelData - track data for one channel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if((loopCnt < 800)|| (trackChannelData.bitSync == 1))
    return; % Nothing to do yet
end

%Consider a time window of 1000 ms
minStartInd = max([loopCnt-100 1]);
phaseDiff = trackChannelData.I_P(minStartInd+1:loopCnt)-trackChannelData.I_P(minStartInd:loopCnt-1);                
normalizedPhaseDiff = phaseDiff/max(phaseDiff);    
phaseChangeIndices = find(abs(normalizedPhaseDiff)>0.6);    
if isempty(phaseChangeIndices)==0    
    for bitInd=1:length(phaseChangeIndices)        
        bitIndCandidate = phaseChangeIndices(bitInd);            
        confidenceLevel = find(mod(abs(phaseChangeIndices(1:end)-bitIndCandidate),2)==0);            
        if length(confidenceLevel)>=6 % There should be at least 3 bit transitions in a total of 10 bits sequence            
            trackChannelData.bitBoundaryIndex=bitIndCandidate+1;                
            trackChannelData.bitBoundaryIndex=mod(trackChannelData.bitBoundaryIndex,2);                
            if trackChannelData.bitBoundaryIndex==0                
                trackChannelData.bitBoundaryIndex=2;                    
            end                
            %Check whether bitSync is really successfull by looking at
            %the I_P correlation values: they should have at least same
            %sign for 20 ms
            if mod(sum(sign(trackChannelData.I_P((loopCnt+trackChannelData.bitBoundaryIndex)-4:(loopCnt+trackChannelData.bitBoundaryIndex)-3))),2)==0
                trackChannelData.bitSync=1;                
                trackChannelData.bitBoundaryIndex=trackChannelData.bitBoundaryIndex;                       
                disp(['   Bit sync for BeiDou GEO prn ', ...
                    int2str(trackChannelData.SvId.satId),' found at ',int2str(loopCnt), ' with index ', int2str(trackChannelData.bitBoundaryIndex)]);
            end
            break;                
        end            
    end        
end    

