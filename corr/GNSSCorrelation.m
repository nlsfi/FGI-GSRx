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
function [tR]= GNSSCorrelation(signalSettings, tR, ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Performs code and carrier correlation for GNSS data
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
fid = tR.fid;
loopCnt = tR.loopCnt;

% Read RF data from file
[tR, rawSignal] = getDataForCorrelation(fid,signalSettings,tR,ch);

% Generate finger data
[fingers,tR] = corrFingerGeneration(signalSettings,tR,ch);

% Carrier generation + correlation and mixing with code signal
tR = carrierMixing(signalSettings,tR,ch, rawSignal);

% Check if user have requested multi correlator tracking
if(mod(loopCnt,tR.multiCorrelatorTrackingRate) == 0)
    if(tR.enableMultiCorrelatorTracking)    
        [mulFingers,tR] = mulCorrFingerGeneration(signalSettings,tR,ch);        
        tR = multiFingerTracking(tR,ch,mulFingers); % Generate fingers for multi finger tracking    
        % if(mod(loopCnt,tR.multiCorrelatorTrackingRate) == 0)
        %     % Plot output
        %     tR.channel(ch) = plotMultiFingerTracking(tR.channel(ch),loopCnt);
        % end
    end
end

% Check where we are in data file
tR.channel(ch).absoluteSample(loopCnt) =(ftell(fid))/(signalSettings.sampleSize/8);
tR.channel(ch).prevAbsoluteSample =tR.channel(ch).absoluteSample(loopCnt);




