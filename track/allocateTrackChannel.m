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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function trackChannel = allocateTrackChannel(trackChannel, allSettings, signal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialises parameters for signal tracking
%
% Inputs:
%   trackChannel    - Data structure for one tracking channel
%   signalSettings  - receiver settings for one signal
%
% Outputs:
%   trackChannel    - Updated data structure for one tracking channel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataLength = allSettings.sys.msToProcess - allSettings.sys.msToSkip;

signalSettings = allSettings.(signal);

% Finger values after correlation
trackChannel.I_E = 0; % I early finger value
trackChannel.I_P = zeros(1,dataLength);  % I prompt finger value
trackChannel.I_L = 0; % I late finger value
trackChannel.Q_E = 0; % Q early finger value
trackChannel.Q_P = zeros(1,dataLength); % Q prompt finger value
trackChannel.Q_L = 0; % Q late finger value
trackChannel.I_E_E = 0; % I very early finger value
trackChannel.Q_E_E = 0; % Q very early finger value
trackChannel.absoluteSample =  zeros(1,dataLength); % Sample count from processed file
trackChannel.prevAbsoluteSample = 0; % Sample count from processed file

% FLL discriminator values
trackChannel.fllDiscr = 0; % FLL discriminator value

% PLL discriminator values
trackChannel.pllDiscr = 0; % PLL discriminator value

% DLL discriminator values
trackChannel.dllDiscr = zeros(1,dataLength); % DLL discriminator value

% DLL Loop values
[trackChannel.tau1code, trackChannel.tau2code] = calcLoopCoef(signalSettings.dllNoiseBandwidth, signalSettings.dllDampingRatio, 1.0);
trackChannel.codeNco = 0; % Feedback value for code NCO
trackChannel.codeError = 0; % Estimated code tracking error
trackChannel.codeFreq   = 0; % Code frequency 
trackChannel.prevCodeNco = 0; % Estimated code NCO value from previous round
trackChannel.prevCodeError = 0; % Estimated code tracking error from previous round
trackChannel.prevCodeFreq = 0;

% FLL Loop values
trackChannel.fllNoiseBandwidthWide = signalSettings.fllNoiseBandwidthWide; % FLL loop bandwidth for wide loop
trackChannel.fllNoiseBandwidthNarrow = signalSettings.fllNoiseBandwidthNarrow; % FLL loop bandwidth for narrow loop
trackChannel.fllNoiseBandwidthVeryNarrow = signalSettings.fllNoiseBandwidthVeryNarrow; % FLL loop bandwidth for narrow loop
trackChannel.fllDampingRatio = signalSettings.fllDampingRatio; % FLL loop damping ratio
trackChannel.fllLoopGain = signalSettings.fllLoopGain; % FLL loop gain
trackChannel.fllFilter = zeros(1,dataLength); % FLL loop filter output
trackChannel.prevIR11 = 0; % Intermediate value from FLL loop filter from previous round

% PLL Loop values
trackChannel.pllNoiseBandwidthWide = signalSettings.pllNoiseBandwidthWide; % PLL loop bandwidth wide
trackChannel.pllNoiseBandwidthNarrow = signalSettings.pllNoiseBandwidthNarrow; % PLL loop bandwidth narrow
trackChannel.pllNoiseBandwidthVeryNarrow = signalSettings.pllNoiseBandwidthVeryNarrow; % PLL loop bandwidth very narrow
trackChannel.pllLoopGain = signalSettings.pllLoopGain; % PLL loop gain
trackChannel.pllDampingRatio = signalSettings.pllDampingRatio; % PLL loop damping ratio
trackChannel.pllFilter = 0; % PLL loop filter output
trackChannel.prevIR4 = 0; % Intermediate value from PLL loop filter from previous round

% phaseFreq Loop values
[trackChannel.tau1carr, trackChannel.tau2carr] = calcLoopCoef(signalSettings.pllNoiseBandwidthWide, signalSettings.pllDampingRatio, signalSettings.pllLoopGain); % using lower FLL filter parameters, added by ST
trackChannel.doppler = zeros(1,dataLength); % Estimated doppler frequency 
trackChannel.prevCarrFreq = 0; % Carrier frequency from previous round
trackChannel.prevCarrError = 0; % Estimated carrier frequency error from previous round
trackChannel.carrFreq   = zeros(1,dataLength); % Carrier frequency 
trackChannel.carrError   = 0; % Estimated carrier frequency error
trackChannel.estCarrFreqFromAcqBlock = trackChannel.acquiredFreq;

% Correlator finger generation
trackChannel.codePhaseStep = 0; % Code phase step when generating code replica
trackChannel.blockSize = 0; % Length of data block to correlate
trackChannel.codePhase = 0;  % Code phase in correlation
trackChannel.carrPhase = 0; % Carrier phase in correlation
trackChannel.prevCarrPhase = 0; % Carrier phase in correlation
trackChannel.prevCodePhase = 0; % Code phase in correlation

% estimate CNO from SNR
trackChannel.noiseCNOfromSNR = zeros(1,dataLength); % Noise calculated from very early finger
trackChannel.CN0fromSNR = zeros(1,dataLength); % CN0 estimated from SNR values
trackChannel.meanCN0fromSNR = zeros(1,dataLength); % Mean of last 1000 CN0 from SNR values

% Bit Sync scripts
trackChannel.bitSync = 0;
trackChannel.bitBoundaryIndex = 0;

% Bit handling
trackChannel.bitValue = 0; 

% Channel specific frequency plan parameters
freqChannel = trackChannel.SvId.satId - 8; % For GLONASS FDMA signals
trackChannel.carrierFreq = signalSettings.carrierFreq + signalSettings.frequencyStep * freqChannel;
trackChannel.carrToCodeRatio = trackChannel.carrierFreq / signalSettings.codeFreqBasis;  
trackChannel.intermediateFreq = signalSettings.intermediateFreq + signalSettings.frequencyStep * freqChannel;

if(strcmp(signalSettings.signal,'beib1'))
    if (trackChannel.SvId.satId > 5) 
        % For MEO/IGSO satellites, Neumann-Hoffman modulation
        trackChannel.bitDuration = signalSettings.bitDurationMEOIGSO;
    else
        % For GEO satellites
        trackChannel.bitDuration = signalSettings.bitDurationGEO;
    end
elseif(strcmp(signalSettings.signal,'glol1'))
     trackChannel.meanderBitDuration = signalSettings.meanderBitDuration;
else
     trackChannel.bitDuration = signalSettings.bitDuration;
end

% FLL lock detector
trackChannel.fllLockIndicator = zeros(1,dataLength);
trackChannel.fllWideBandLockIndicatorThreshold=signalSettings.fllWideBandLockIndicatorThreshold;
trackChannel.fllNarrowBandLockIndicatorThreshold=signalSettings.fllNarrowBandLockIndicatorThreshold;
trackChannel.runningAvgWindowForLockDetectorInMs=signalSettings.runningAvgWindowForLockDetectorInMs;
% PLL lock detector
trackChannel.pllLockIndicator = zeros(1,dataLength);
trackChannel.pllWideBandLockIndicatorThreshold=signalSettings.pllWideBandLockIndicatorThreshold;
trackChannel.pllNarrowBandLockIndicatorThreshold=signalSettings.pllNarrowBandLockIndicatorThreshold;

trackChannel.bitSyncConfidenceLevel = signalSettings.bitSyncConfidenceLevel;



