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
function [fingers,tR] = corrFingerGeneration(signalSettings,tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Generates all the correlator fingers
%
% Inputs:
%   tR              - Track data for all channels
%   ch              - Channel number for processing
%
% Outputs:
%   tR              - track data for one channel
%   fingers         - Generated finger data
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set local variables
trackChannelData = tR.channel(ch);
loopCnt = tR.loopCnt;
if(trackChannelData.bInited)
    codePhase  = trackChannelData.prevCodePhase; % residual code phase from previous round
else
    codePhase  = 0; % First epoch. No previous value exist
end
codePhaseStep = trackChannelData.codePhaseStep;
blockSize = trackChannelData.blockSize(loopCnt);
Code = trackChannelData.codeReplica(1,:);
scalingFactor = signalSettings.modulationFactor;

nrOfFingers = length(trackChannelData.corrFingers);
corrFingers = trackChannelData.corrFingers;

% Get first and last finger
negOffset = abs(corrFingers(1)); % [-2 -0.25 0 0.25],
posOffset = corrFingers(end);

% Calculate biggest offset and number of fingers
dataToAdd = max(negOffset,posOffset);



% We need to fill in data on both sides of the code replica 
% in order to be able to generate the finger data
add_data = dataToAdd + 100; % Add some extra data at both ends
add_data = floor(add_data);

% This is the long code with data added on both sides
longCode = [Code(end-add_data+1:end) Code Code(1:add_data)];

% Time stamps for for prompt finger (TBA: DO we need this)
tcode       = ((codePhase) : ...
              codePhaseStep : ...
              ((blockSize-1)*codePhaseStep+codePhase))*scalingFactor;         
tcode(blockSize) = tcode(blockSize)./scalingFactor;
fingers.tcode = tcode;

% Let's generate all early and late fingers
for i=1:nrOfFingers
    pos = corrFingers(i); % Offset for finger 
    
    % Time code for given offset
    tcode       = ((codePhase+pos) : ...
                  codePhaseStep : ...
                  ((blockSize-1)*codePhaseStep+codePhase+pos))*scalingFactor;
    tcode2      = ceil(tcode + add_data); % Add data also for time stamps TBA: Why ?
    
    % Generate codes
    fingers.Code(i,:)   = longCode(tcode2);   
end

% Copy data
trackChannelData.earlyCode = fingers.Code(trackChannelData.earlyFingerIndex,:);
trackChannelData.lateCode = fingers.Code(trackChannelData.lateFingerIndex,:);
trackChannelData.promptCode = fingers.Code(trackChannelData.promptFingerIndex,:);
trackChannelData.twoChipEarlyCode = fingers.Code(trackChannelData.noiseFingerIndex,:);

% Data channel correlator for GPS L1C
if strcmp(signalSettings.signal,'gpsl1c')
    dataCode = trackChannelData.codeReplicaL1CD(1,:);
    longDataCode = [dataCode(end-add_data+1:end) dataCode dataCode(1:add_data)];
    tDataCode       = ceil((codePhase : codePhaseStep : ((blockSize-1)*codePhaseStep+codePhase))*scalingFactor + add_data);
    trackChannelData.promptDataCode = longDataCode(tDataCode); 
end

% Calculate code phase
codePhase = (fingers.tcode(blockSize) + trackChannelData.codePhaseStep) - signalSettings.codeLengthInChips;
trackChannelData.codePhase(loopCnt) = codePhase; % Copy for use in next round
trackChannelData.prevCodePhase = codePhase; % Copy for use in next round

% Copy updated local variables
tR.channel(ch) = trackChannelData;
