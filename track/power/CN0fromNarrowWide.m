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
function tR = CN0fromNarrowWide(tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function for estimating CN0 from narrowband and wideband power
%
% Inputs:
%   tR             - Results from signal tracking for one signals
%   ch             - Channel index
%
% Outputs:
%   tR             - Results from signal tracking for one signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TBA Reference ?
% Rearrange so that we separte update something every k and something every k*M

% Set local variables
trackChannelData = tR.channel(ch);
loopCnt = trackChannelData.loopCnt;

if mod(loopCnt,trackChannelData.M)~=0
    return; % Nothing to do
end

% Set local variables
kIndex = trackChannelData.kIndex;    
CN0_index=(loopCnt)/trackChannelData.M;

% Extract start and end bits
if trackChannelData.bitSync==1
    startBitInd = (loopCnt+trackChannelData.bitBoundaryIndex)-40; 
    endBitInd = (loopCnt+trackChannelData.bitBoundaryIndex)-21; 
    endBitInd=min([loopCnt endBitInd]);
else
    startBitInd=loopCnt-19;
    endBitInd=min([loopCnt length(trackChannelData.I_P)]);
end    

% Calculate wide and narrowband power
[wide,narrow] = narrowWidePower(trackChannelData,tR.signal,startBitInd,endBitInd);
trackChannelData.wideBandPower(loopCnt) = wide;
trackChannelData.narrowBandPower(loopCnt) = narrow;

% Calculate normalised power and mean
trackChannelData.normalizedPower(loopCnt) = trackChannelData.narrowBandPower(loopCnt)/trackChannelData.wideBandPower(loopCnt);
trackChannelData.meanNormalizedPower(loopCnt)=mean(trackChannelData.normalizedPower(kIndex * trackChannelData.M:trackChannelData.M:loopCnt));

trackChannelData.powerError(loopCnt) = (sqrt(sum(trackChannelData.I_E(startBitInd:endBitInd)) * sum(trackChannelData.I_E(startBitInd:endBitInd)) + ...
            sum(trackChannelData.Q_E(startBitInd:endBitInd)) * sum(trackChannelData.Q_E(startBitInd:endBitInd))) - ...
            sqrt(sum(trackChannelData.I_L(startBitInd:endBitInd)) * sum(trackChannelData.I_L(startBitInd:endBitInd)) + ...
            sum(trackChannelData.Q_L(startBitInd:endBitInd)) * sum(trackChannelData.Q_L(startBitInd:endBitInd)))) / ...
            (sqrt(sum(trackChannelData.I_E(startBitInd:endBitInd)) * sum(trackChannelData.I_E(startBitInd:endBitInd)) + ...
            sum(trackChannelData.Q_E(startBitInd:endBitInd)) * sum(trackChannelData.Q_E(startBitInd:endBitInd))) + ...
            sqrt(sum(trackChannelData.I_L(startBitInd:endBitInd)) * sum(trackChannelData.I_L(startBitInd:endBitInd)) + ...
            sum(trackChannelData.Q_L(startBitInd:endBitInd)) * sum(trackChannelData.Q_L(startBitInd:endBitInd))));
                    
% Calculate CN0 values
if mod(CN0_index,trackChannelData.K)==0
    trackChannelData.kIndex = loopCnt / trackChannelData.M + 1;                                               
    trackChannelData.CN0fromNarrowWide(loopCnt)=  trackChannelData.CN0Coeff * abs(10*log10((1/(trackChannelData.Nc)) ...
                                               * (trackChannelData.meanNormalizedPower(loopCnt)-1) ...
                                               / (trackChannelData.M-trackChannelData.meanNormalizedPower(loopCnt))));                                           
end    

tR.channel(ch) = trackChannelData;


