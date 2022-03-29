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
function [trackResults]= doTracking(acqResults, allSettings)
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
trackStartTime = now;

% UI output
disp (['   Tracking started at ', datestr(trackStartTime)]); 

% Initialise tracking structure
trackResults = initTracking(acqResults, allSettings);  

% Let's loop over all enabled signals and open files for reading
for signalNr = 1:allSettings.sys.nrOfSignals

    % Extract block of parameters for one signal from settings
    signal = allSettings.sys.enabledSignals{signalNr};
    signalSettings = allSettings.(signal);
    
    % Open file for reading
    [fid, message] = fopen(signalSettings.rfFileName, 'rb');
    if (fid == -1)
       error('Failed to open data file for tracking!');
       return;
    else
       fidTemp{signalNr} = fid;
    end
end

t1=clock;

for loopCnt =  1:allSettings.sys.msToProcess % Loop over all epochs
    for signalNr = 1:allSettings.sys.nrOfSignals % Loop over all signals
        signal = allSettings.sys.enabledSignals{signalNr};
        
        for channelNr = 1:trackResults.(signal).nrObs % Loop over all channels
            trackResults.(signal).channel(channelNr).loopCnt = loopCnt;
             % Set file pointer
            trackResults.(signal).fid = fidTemp{signalNr};

            % Check epoch boundary
            if(mod(loopCnt,trackResults.(signal).codeLengthInMs)==0)
                
                % Correlate signal
                trackResults.(signal) = GNSSCorrelation(trackResults.(signal),channelNr);             
                
                % Tracking of signal
                trackResults.(signal) = GNSSTracking(trackResults.(signal),channelNr); 
            end
        end
    end
    
    % UI function
    if (mod(loopCnt, 100) == 0)   
        t2 = clock;
        time = etime(t2,t1);
        estimtime = allSettings.sys.msToProcess/loopCnt * time;
%         showTrackStatus(trackResults,allSettings,loopCnt);
        msProcessed = loopCnt;
        msLeftToProcess = allSettings.sys.msToProcess-loopCnt;
        disp(['Ms Processed: ',int2str(msProcessed),' Ms Left: ',int2str(msLeftToProcess)]);
%         disp(['Time processed: ',int2str(time),' Time left: ',int2str(estimtime-time)]);

     end    
end % Loop over all epochs

% Notify user tracking is over
disp(['   Tracking is over (elapsed time ', datestr(now - trackStartTime, 13), ')']) 


