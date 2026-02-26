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
function trackData = doTrackingPCT(trackDataFileName, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes input of acquisition results and performs tracking.
%
% Inputs:
%   trackDataFileName      - Tracking data file names for all the
%   satellites of all the specified constellations  
%   allSettings            - Receiver settings
%
% Outputs:
%   trackData    - Results from signal tracking for all signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


numberOfPhysicalCores = feature('numcores');
c = parcluster('Processes'); % or use parcluster('local') pre-R2022b.;
c. NumWorkers = numberOfPhysicalCores; % choose the new value you want. Using 10 here as an example.
saveProfile(c) % will overwrite the profile with the new NumWorkers value.
channelCounter = 0;
for signalNr = 1:allSettings.sys.nrOfSignals % Loop over all signals        
    signal = allSettings.sys.enabledSignals{signalNr};
    for channelNr = 1:length(trackDataFileName.(signal).channel) % Loop over all channels  
        channelCounter = channelCounter + 1;
        trackDataFileNameAllSignals(channelCounter).name=[trackDataFileName.(signal).channel(channelNr).name];
    end
end
totalNumberOfChannels = channelCounter;
if(totalNumberOfChannels >numberOfPhysicalCores)
    parpoolnum = numberOfPhysicalCores;
else
    parpoolnum = totalNumberOfChannels;
end

parpool(parpoolnum);
parfor channelNr = 1:totalNumberOfChannels % Loop over all channels 
   doTrackingSingleChannelParFor(trackDataFileNameAllSignals(channelNr).name);
end
delete(gcp('nocreate'));

for signalNr = 1:allSettings.sys.nrOfSignals % Loop over all signals        
    signal = allSettings.sys.enabledSignals{signalNr};        
    for channelNr = 1:length(trackDataFileName.(signal).channel) % Loop over all channels            
        trackDataFileNamePerChannel = [trackDataFileName.(signal).channel(channelNr).name];
        load(trackDataFileNamePerChannel);          
        trackDataCombined.(signal).channel(channelNr) = trackResults.(signal).channel;        
        trackDataCombined.(signal).signal = trackResults.signal;
    end    
    trackDataCombined.(signal).nrObs = length(trackDataFileName.(signal).channel);                     
    trackDataCombined.(signal).PDIcarr = trackResults.(signal).PDIcarr;
    trackDataCombined.(signal).PDIcode = trackResults.(signal).PDIcode;
end % Loop over all epochs         
  
trackData = trackDataCombined;



