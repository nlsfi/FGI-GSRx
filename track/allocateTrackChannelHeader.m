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
function tC = allocateTrackChannelHeader(aR, ch, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialises generic variables in trackChannel structure
%
% Inputs:
%   aR              - Results from signal acquisition for one signal
%   ch              - Channel index
%   allSettings     - receiver settings.
%
% Outputs:
%   tC              - Initialised track channel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extract local variables
signal = aR.signal;
signalSettings = allSettings.(signal);    
acqChannel = aR.channel(ch);
prn = acqChannel.SvId.satId;

% Copy data from acquisition
tC.SvId          = acqChannel.SvId;
tC.acquiredFreq = acqChannel.carrFreq;
tC.acquiredCodePhase    = acqChannel.codePhase;

% Set state related variables
tC.bInited       = false;
tC.trackState = 'STATE_PULL_IN';        

% Add code replica
prnFunc = str2func([signal,'GeneratePrnCode']);
Code = prnFunc(prn);
modulateFunc = str2func([signal,'ModulatePrnCode']);
modulatedCode = modulateFunc(Code, signalSettings);
tC.codeReplica = modulatedCode;
% Set tracking table
trackTableFunc = str2func([signalSettings.signal,'setTrackingTable']);
tC = trackTableFunc(tC,tC.trackState);

% Generated code and carrier in correlation
tC.earlyCode = 0;
tC.lateCode = 0;
tC.promptCode = 0;
tC.twoChipEarlyCode = 0;
tC.qBasebandSignal = 0;
tC.iBasebandSignal = 0;

% Update rates in sec
tC.PDIcarr = signalSettings.Nc;
tC.PDIcode = signalSettings.Nc;

% Loop counters
tC.loopCnt = 0;




