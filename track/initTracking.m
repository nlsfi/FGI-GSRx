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
function [trackResults] = initTracking(acqResults, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function initializes tracking channels from acquisition data. 
%
% Inputs:
%   acqResults      - Results from signal acquisition for all signals
%   allSettings     - Receiver settings
%
% Outputs:
%   trackResults    - Results from signal tracking for all signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over all signals
for i = 1:allSettings.sys.nrOfSignals
    
    % Select acquisition results and parameter block
    signal = allSettings.sys.enabledSignals{i};
    signalSettings = allSettings.(signal);

    % Set signal specific parameters, i.e. non channel specific
    trackResults.(signal).nrObs = sum([acqResults.(signal).channel.bFound]);
    trackResults.(signal).signal = signalSettings.signal;
    trackResults.(signal).fid = 0;
    
    trackResults.(signal) = getFreqPlanParameters(trackResults.(signal),signalSettings);
    trackResults.(signal).numberOfBytesToSkip = signalSettings.numberOfBytesToSkip;
    trackResults.(signal).numberOfBytesToRead = signalSettings.numberOfBytesToRead;
    
    trackResults.(signal).enableMultiCorrelatorTracking = allSettings.sys.enableMultiCorrelatorTracking;
    trackResults.(signal).multiCorrelatorTrackingRate = allSettings.sys.multiCorrelatorTrackingRate;
    
    % Set channel specific parameters
    ind = 1;
    for k=1:acqResults.(signal).nrObs
        if(acqResults.(signal).channel(k).bFound == true)
            trackChannel = allocateTrackChannelHeader(acqResults.(signal), k, allSettings);
            trackChannel = allocateTrackChannel(trackChannel,signalSettings);

            % Mode specific configuration
            if ((allSettings.sys.enableMultiCorrelatorTracking == true) && ...
                    (ind == allSettings.sys.multiCorrelatorTrackingChannel))
                trackChannel = getCorrelatorFingers(trackChannel,allSettings.sys);
            else
                trackChannel = getCorrelatorFingers(trackChannel,signalSettings);
            end

            trackResults.(signal).channel(ind) = trackChannel;
            ind = ind + 1;
        end
        
    end
end

