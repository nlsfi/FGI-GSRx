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
function [tR]  = carrierMixing(signalSettings,tR, ch, pRfData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Carrier and code mixing (correlation)
%
% Inputs:
%   tR              - Results from signal tracking for one signals
%   ch              - Channel index
%   pRfData         - RF data from file
%
% Outputs:
%   tR              - Results from signal tracking for one signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set local variables
trackChannelData = tR.channel(ch);
loopCnt = tR.loopCnt;
blockSize = trackChannelData.blockSize(loopCnt);
if(trackChannelData.bInited)
    carrFreq      = trackChannelData.acquiredFreq + trackChannelData.prevCarrFreq;
    carrPhase  = trackChannelData.prevCarrPhase; % define residual carrier phase    
else
    carrFreq = trackChannelData.acquiredFreq; % Firts round so use default values
    carrPhase = 0;
end

% Get time stamps for carrier signal
time    = (0:blockSize) ./ signalSettings.samplingFreq;

% Get the argument to sin/cos functions
trigarg = -((carrFreq * 2.0 * pi) .* time) + carrPhase;

% Compute the carrier replica signal
carrSignal = exp(i .* trigarg(1:blockSize));

% Mix signal to baseband
iBasebandSignal = real(carrSignal .* pRfData);
qBasebandSignal = imag(carrSignal .* pRfData);

% Mix with code replicas
trackChannelData.I_E = sum(trackChannelData.earlyCode  .* iBasebandSignal);
trackChannelData.I_P(loopCnt) = sum(trackChannelData.promptCode      .* iBasebandSignal);
trackChannelData.I_L = sum(trackChannelData.lateCode   .* iBasebandSignal);
trackChannelData.Q_E = sum(trackChannelData.earlyCode  .* qBasebandSignal);
trackChannelData.Q_P(loopCnt) = sum(trackChannelData.promptCode      .* qBasebandSignal);
trackChannelData.Q_L = sum(trackChannelData.lateCode   .* qBasebandSignal);     
trackChannelData.I_E_E = sum(trackChannelData.twoChipEarlyCode  .* iBasebandSignal);
trackChannelData.Q_E_E = sum(trackChannelData.twoChipEarlyCode  .* qBasebandSignal);

if strcmp(signalSettings.signal,'gpsl1c')
    trackChannelData.dataI_P(loopCnt) = sum(trackChannelData.promptDataCode .* iBasebandSignal);
end

% Copy data 
trackChannelData.prevCarrPhase = rem(trigarg(blockSize+1), (2 * pi)); 
trackChannelData.carrPhase(loopCnt) = rem(trigarg(blockSize+1), (2 * pi)); 
trackChannelData.qBasebandSignal = qBasebandSignal;
trackChannelData.iBasebandSignal = iBasebandSignal;

% Copy updated local variables
tR.channel(ch) = trackChannelData;



