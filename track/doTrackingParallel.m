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
function doTrackingParallel(trackDataFileName, allSettings)
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
    

%Create BacthFile
currentWorkingDirectoryForFGIGSRx = allSettings.sys.currentWorkingDirectoryForFGIGSRx;
batchFileName=[currentWorkingDirectoryForFGIGSRx, 'main\' allSettings.sys.batchFileNameToRunParallelTracking];
fid = fopen(batchFileName, 'wt' );
if (fid == -1)
   error('Failed to open data file for tracking!');
   return;
end
for signalNr = 1:allSettings.sys.nrOfSignals % Loop over all signals        
    signal = allSettings.sys.enabledSignals{signalNr};                 
    for channelNr = 1:length(trackDataFileName.(signal).channel) % Loop over all channels            
        trackDataFileNameForEachSignal = trackDataFileName.(signal).channel(channelNr).name;        
        load(trackDataFileNameForEachSignal);              
        %matlab -nosplash -nodesktop -minimize -r "addpath(genpath('D:/ZB Oct23/FGI-GSRx-OS 10Nov23/')); cd('D:/ZB Oct23/FGI-GSRx-OS 10Nov23/'); load 'D:\Raw IQ Data\OSNMA data\trackDataSingleChannel_1.mat'; doTrackingSingleChannel(trackResultsSingle,allSettings)"                     
        runMATLABcommand = ['matlab -nosplash -nodesktop -minimize -r ', '"','addpath(genpath(''',currentWorkingDirectoryForFGIGSRx,''')); load ''',trackDataFileNameForEachSignal,'''; doTrackingSingleChannel(acqData,trackResultsSingle,allSettings);"'];        
        fprintf(fid,'%s\n', runMATLABcommand);        
    end          
end % Loop over all epochs         
fclose(fid);

% trackDataFileName = ['D:\Raw IQ Data\OSNMA data\trackDataSatellite_ID_',num2str(trackResults.(signal).channel.SvId.satId),'.mat'];
% save(trackDataFileName, 'trackResults', 'allSettings');
% % Notify user tracking is over
% disp(['   Tracking is over (elapsed time ', datestr(now - trackStartTime, 13), ')']) 


