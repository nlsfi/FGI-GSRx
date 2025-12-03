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
function tR = lockDetect(signalSettings,tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lock Detector function for all signals
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


step = (signalSettings.Nc*1000);
runningAvgWindowForLockDetectorInMs = trackChannelData.runningAvgWindowForLockDetectorInMs;
startInd = max([0 loopCnt-runningAvgWindowForLockDetectorInMs])+step;        
endInd = min([loopCnt length(trackChannelData.I_P)]);
alpha = 0.01;

if(trackChannelData.bInited)
    IP_1 = trackChannelData.I_P(loopCnt-step);
    QP_1 = trackChannelData.Q_P(loopCnt-step);
else
    IP_1 = 0.001;
    QP_1 = 0.001;    
end
IP_2 = trackChannelData.I_P(loopCnt);
QP_2 = trackChannelData.Q_P(loopCnt);        



%Frequency Lock Indicator: implemented from the paper: 
% Ma, C., Lachapelle, G., Cannon, M.E., "Implementation of a Software GPS Receiver," 
% Proceedings of the 17th International Technical Meeting of the Satellite Division of 
% The Institute of Navigation (ION GNSS 2004), Long Beach, CA, September 2004, pp. 956-970.
fllLockIndicator = abs((IP_2*IP_1 - QP_2*QP_1)*sign((IP_2*IP_1 + QP_2*QP_1)))/((IP_2*IP_2)+ (QP_2*QP_2));

if loopCnt/step>1
    trackChannelData.fllLockIndicator(loopCnt)=(1-alpha)*fllLockIndicator+ alpha*trackChannelData.fllLockIndicator(loopCnt-step);
else
    trackChannelData.fllLockIndicator(loopCnt)=fllLockIndicator;
end
%Update the running average window
trackChannelData.fllLockIndicator(loopCnt) = mean(trackChannelData.fllLockIndicator(startInd:step:endInd));


% Phase lock detector implementation based on Parkinson's book Volume I,
% page 393

narrowBandDifference = sum(abs(trackChannelData.I_P(startInd:step:endInd)))^2 ...
                     - sum(abs(trackChannelData.Q_P(startInd:step:endInd)))^2; 
   
narrowBandPower = sum(abs(trackChannelData.I_P(startInd:step:endInd)))^2 ...
                + sum(abs(trackChannelData.Q_P(startInd:step:endInd)))^2; 
            
lock = abs(narrowBandDifference/narrowBandPower);

trackChannelData.pllLockIndicator(loopCnt) = lock;  

% Copy updated local variables
tR.channel(ch) = trackChannelData;
