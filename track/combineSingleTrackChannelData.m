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
function trackDataCombined = combineSingleTrackChannelData(allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes input of acquisition results and performs tracking.
%
% Inputs:
%   allSettings     - Receiver settings
%
% Outputs:
%   trackDataCombined    - Combined tracking data for all the satellites
%   from all the specified constellations: tracking data file name and file 
%   path for one single satellite is given in the user confirugation file:
%   the receiver then combined all the tracking data files available in the 
%   speficic file path
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trackDataInputFile= allSettings.sys.dataFileIn;
trackDataFilePath = allSettings.sys.trackDataFilePath;

for signalNr = 1:allSettings.sys.nrOfSignals % Loop over all signals   
    
    signal = allSettings.sys.enabledSignals{signalNr};
    load(trackDataInputFile);

    trackDataCombined.(signal) = trackResults.(signal);
    trackDataCombined.(signal).channel(1).trackingRunTime= 0;
    trackChannelNr = 1;
  
    for channelNr = 1:length(acqData.(signal).channel) % Loop over all channels            
        if acqData.(signal).channel(channelNr).bFound == 1
            satId = acqData.(signal).channel(channelNr).SvId.satId;
            trackDataFileName = [trackDataFilePath,'trackData_',signal,'_Satellite_ID_',num2str(satId),'.mat'];
            load(trackDataFileName);        
            trackDataCombined.(signal).channel(trackChannelNr) = trackResults.(signal).channel;
            trackDataCombined.(signal).fid = trackResults.(signal).fid;
            trackDataCombined.(signal).nrObs = trackDataCombined.(signal).nrObs+1;         
            trackChannelNr = trackChannelNr + 1; 
        end
    end % Loop over all epochs         
    trackDataCombined.(signal).nrObs = trackDataCombined.(signal).nrObs - 1;
end
