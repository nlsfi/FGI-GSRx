%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FGI-GSRx software GNSS receiver
%
% Finnish Geospatial Research Institute
% Department of Navigation and Positioning
% DO NOT DISTRIBUTE
%
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tR = gpsl1cUpdateChannelState(signalSettings,tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update track state for gps L1C signals
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
loopCnt = tR.loopCnt;

% Switch between tracking states
if trackChannelData.fllLockIndicator(loopCnt)<trackChannelData.fllWideBandLockIndicatorThreshold 
    trackChannelData.trackState = 'STATE_PULL_IN';
elseif (trackChannelData.fllLockIndicator(loopCnt)>=trackChannelData.fllWideBandLockIndicatorThreshold && ...
       trackChannelData.fllLockIndicator(loopCnt)<trackChannelData.fllNarrowBandLockIndicatorThreshold)       
    trackChannelData.trackState = 'STATE_COARSE_TRACKING';        
elseif (trackChannelData.fllLockIndicator(loopCnt)>=trackChannelData.fllNarrowBandLockIndicatorThreshold ...
        && trackChannelData.pllLockIndicator(loopCnt)>=trackChannelData.pllNarrowBandLockIndicatorThreshold)
    trackChannelData.trackState = 'STATE_FINE_TRACKING';    
end

% Update tracking table
trackChannelData = gpsl1csetTrackingTable(trackChannelData, trackChannelData.trackState);

% Finally update variables at end of run
trackChannelData.bInited = true;

% Copy updated local variables
tR.channel(ch) = trackChannelData;
