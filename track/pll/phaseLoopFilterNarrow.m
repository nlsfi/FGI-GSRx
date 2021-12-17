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
function tR = phaseLoopFilterNarrow(tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PLL loop filter for all signals
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
BWPLL = trackChannelData.pllNoiseBandwidthNarrow;
loopGainPLL = trackChannelData.pllLoopGain;
dampingRatioPLL = trackChannelData.pllDampingRatio;
PDIcarr = trackChannelData.PDIcarr;

% Calculate phase error from discriminator function
pllDiscr = trackChannelData.pllDiscr(loopCnt);

% Phase locked loop filter
Wn = (8*dampingRatioPLL*BWPLL)/(4*dampingRatioPLL^2 + 1);
c1 = (1/loopGainPLL)*(8*dampingRatioPLL*Wn*PDIcarr)/(4+(4*dampingRatioPLL*Wn*PDIcarr)+(Wn*PDIcarr)^2);
c2 = (1/loopGainPLL)*(4*(Wn*PDIcarr)^2)/(4+(4*dampingRatioPLL*Wn*PDIcarr)+(Wn*PDIcarr)^2);

IR1 = pllDiscr*c2*PDIcarr;
IR2 = pllDiscr*c1;

if(trackChannelData.bInited)
    IR3 = trackChannelData.prevIR4;
else
    IR3 = 0.0;
end
IR4 = IR1 + IR3;
IR5 = IR4 + IR3;
IR6 = 0.5*IR5;
IR7 = IR6 + IR2;
trackChannelData.pllFilter(loopCnt)   = IR7;

% Store values for next round
trackChannelData.prevIR4 = IR4;

% Copy updated local variables
tR.channel(ch) = trackChannelData;




