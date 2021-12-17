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
function tR = freqLoopFilterWide(tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wide bandwidth FLL loop filter for pull-in for all signals
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
BWFLL = trackChannelData.fllNoiseBandwidthWide;
dampingRatioFLL = trackChannelData.fllDampingRatio;
loopGainFLL = trackChannelData.fllLoopGain;
PDIcarr = trackChannelData.PDIcarr;

% Calculate frequency error from discriminator function
fllDiscr = trackChannelData.fllDiscr(loopCnt);

% Freuqency locked loop filter (wide band)
Wn = (8*dampingRatioFLL*BWFLL)/(4*dampingRatioFLL^2 + 1);
c1 = (1/loopGainFLL)*(8*dampingRatioFLL*Wn*PDIcarr)/(4+(4*dampingRatioFLL*Wn*PDIcarr)+(Wn*PDIcarr)^2);
c2 = (1/loopGainFLL)*(4*(Wn*PDIcarr)^2)/(4+(4*dampingRatioFLL*Wn*PDIcarr)+(Wn*PDIcarr)^2);

IR8 = fllDiscr*c2*PDIcarr;
IR9 = fllDiscr*c1;

if(trackChannelData.bInited)
    IR10 = trackChannelData.prevIR11;
else
    IR10 = 0.0;
end
IR11 = IR8 + IR10;
IR12 = IR11 + IR10;
IR13 = 0.5*IR12;
IR14 = IR13 + IR9;
trackChannelData.fllFilter(loopCnt)   = IR14;

% Store values for next round
trackChannelData.prevIR11 = IR11;


% Copy updated local variables
tR.channel(ch) = trackChannelData;

