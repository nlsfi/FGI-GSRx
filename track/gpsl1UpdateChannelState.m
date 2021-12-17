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
function tR = gpsl1UpdateChannelState(tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update track state for gps tracking
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

% Switch between tracking states
if trackChannelData.fllLockIndicator(loopCnt)<trackChannelData.fllWideBandLockIndicatorThreshold %(trackChannelData.phaseLock == 0) 
    trackChannelData.trackState = 'STATE_PULL_IN';
elseif (trackChannelData.fllLockIndicator(loopCnt)>=trackChannelData.fllWideBandLockIndicatorThreshold && ...
       trackChannelData.fllLockIndicator(loopCnt)<trackChannelData.fllNarrowBandLockIndicatorThreshold) 
    trackChannelData.trackState = 'STATE_COARSE_TRACKING';    
elseif (trackChannelData.bitSync ==1 && trackChannelData.fllLockIndicator(loopCnt)>=trackChannelData.fllNarrowBandLockIndicatorThreshold && ...
        trackChannelData.pllLockIndicator(loopCnt)>=trackChannelData.pllNarrowBandLockIndicatorThreshold)
    trackChannelData.trackState = 'STATE_FINE_TRACKING';
end

% Update tracking table
trackChannelData = gpsl1setTrackingTable(trackChannelData, trackChannelData.trackState);

% Finally update variables at end of run
trackChannelData.bInited = true;

% Copy updated local variables
tR.channel(ch) = trackChannelData;

