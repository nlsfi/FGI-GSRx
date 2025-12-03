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
function tR = phaseFreqFilter(signalSettings,tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Last Loop filter 
%
% Inputs:
%   tR             - Results from signal tracking for one signals
%   ch             - Channel index
%
% Outputs:
%   tR             - Results from signal tracking for one signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% After acquisition of a satellite, the carrier tracking for the satellite proceeds in 2 phases:
% Phase 1 = pull_in = FLL only with 3rd order loop filtering
% Phase 2 = tracking = PLL only with 3rd order loop filtering

% Copy updated local variables
trackChannelData = tR.channel(ch);
loopCnt = tR.loopCnt;
tau1carr = trackChannelData.tau1carr;
tau2carr = trackChannelData.tau2carr;
PDIcarr = tR.PDIcarr;
carrFreqBasis = trackChannelData.acquiredFreq;
if(trackChannelData.bInited)
    oldCarrNco   = trackChannelData.prevCarrFreq;
    oldCarrError = trackChannelData.prevCarrError;
else
    oldCarrNco   = 0;
    oldCarrError = 0;
end

% Calculate normalised PLL filter output
pllDiscrFilt = trackChannelData.pllFilter;

% Calculate normalised FLL filter output
fllDiscrFilt = trackChannelData.fllFilter;
% Calculate total carrier error
if (strcmp(trackChannelData.trackState, 'STATE_PULL_IN') == 1) %phase 1
    % total carrier tracking error = frequency error
    totalCarrError = fllDiscrFilt;
    pllNoiseBandwidth = trackChannelData.pllNoiseBandwidthWide;    
elseif (strcmp(trackChannelData.trackState, 'STATE_COARSE_TRACKING') == 1)  %phase 2
    % total carrier tracking error = frequency error + phase error
    pllNoiseBandwidth = trackChannelData.pllNoiseBandwidthNarrow;    
    totalCarrError = fllDiscrFilt + pllDiscrFilt;
elseif (strcmp(trackChannelData.trackState, 'STATE_FINE_TRACKING') == 1)  %phase 2
    % total carrier tracking error = frequency error + phase error
    pllNoiseBandwidth = trackChannelData.pllNoiseBandwidthVeryNarrow;    
    totalCarrError = fllDiscrFilt + pllDiscrFilt;    
end

[trackChannelData.tau1carr, trackChannelData.tau2carr] = calcLoopCoef(pllNoiseBandwidth, ...
                                                             trackChannelData.pllDampingRatio, trackChannelData.pllLoopGain); 
trackChannelData.carrError = totalCarrError;

% Calculate NCO feedback
carrNco        = ((tau2carr/tau1carr) * (totalCarrError - oldCarrError) + totalCarrError * (PDIcarr/tau1carr)) + oldCarrNco;

% Calculate carrier frequency
carrFreq       = carrFreqBasis + carrNco;
trackChannelData.carrFreq(loopCnt)          = carrFreq;

% Store values for next round
trackChannelData.prevCarrFreq = carrNco;
trackChannelData.prevCarrError = totalCarrError;

% Calcualte doppler frequency
trackChannelData.doppler(loopCnt)           = carrFreq - trackChannelData.intermediateFreq; %doppler = (IF frequency estimate during current loop of PLL) - (base IF freq)


% Copy updated local variables
tR.channel(ch) = trackChannelData;

