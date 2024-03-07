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
function doTrackingSingleChannel(acqData,trackResults, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes input of acquisition results and performs tracking.
%
% Inputs:
%   acqResults      - Results from signal acquisition for all signals
%   allSettings     - Receiver settings
%
% Outputs:
%   trackResults    - Results from signal tracking for all signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Start timer for tracking
trackStartTime = tic;
trackStartTimeInstance = now; 
% UI output
disp (['   Tracking started at ', datestr(trackStartTimeInstance)]); 

% Select acquisition results and parameter block
signal = trackResults.signal;
signalSettings = allSettings.(signal);
saveEnabledSignals = allSettings.sys.enabledSignals;
saveNrOfSignals = allSettings.sys.nrOfSignals;
allSettings.sys.nrOfSignals = 1;
index= strcmp(saveEnabledSignals,signal);
allSettings.sys.enabledSignals = saveEnabledSignals{index};

% Open file for reading    
[fid, message] = fopen(signalSettings.rfFileName, 'rb');
if (fid == -1)
    error('Failed to open data file for tracking!');
    return;    
end


t1=clock;
trackResults.(signal).fid = fid;
for loopCnt =  1:allSettings.sys.msToProcess % Loop over all epochs        
    trackResults.(signal).loopCnt = loopCnt;
    channelNr = 1; % Loop over all channels            
    % Set file pointer    
    % Check epoch boundary        
    if(mod(loopCnt,allSettings.(signal).codeLengthMs)==0)                        
        % Correlate signal            
        trackResults.(signal) = GNSSCorrelation(allSettings.(signal),trackResults.(signal),channelNr);                         
        % Tracking of signal            
        trackResults.(signal) = GNSSTracking(allSettings.(signal),trackResults.(signal),channelNr);             
    end               
    % UI function
    if (mod(loopCnt, 1000) == 0)   
        t2 = clock;
        time = etime(t2,t1);
        estimtime = allSettings.sys.msToProcess/loopCnt * time;
        showTrackStatusSingle(trackResults,allSettings,loopCnt);
        msProcessed = loopCnt;
        msLeftToProcess = allSettings.sys.msToProcess-loopCnt;
        disp(['Ms Processed: ',int2str(msProcessed),' Ms Left: ',int2str(msLeftToProcess)]);
        disp(['Time processed: ',int2str(time),' Time left: ',int2str(estimtime-time)]);
     end    
end % Loop over all epochs
trackResults.(signal).channel(channelNr).trackingRunTime = toc(trackStartTime);
trackDataFilePath = allSettings.sys.trackDataFilePath;

trackDataFileName = [trackDataFilePath,'trackData_',signal,'_Satellite_ID_',num2str(trackResults.(signal).channel.SvId.satId),'.mat'];

allSettings.sys.enabledSignals=saveEnabledSignals;
allSettings.sys.nrOfSignals=saveNrOfSignals;


save(trackDataFileName, 'trackResults', 'allSettings','acqData');
% Notify user tracking is over
disp(['   Tracking is over (elapsed time ', datestr(now - trackStartTimeInstance, 13), ')']) 


