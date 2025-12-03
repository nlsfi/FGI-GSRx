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
function [obsData, nrOfEpochs, startSampleCount, navData, samplesPerMs] = initNavigation(obsData, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates some initial values needed for the main
% navigation loop
%
% Inputs: 
%   obsData             - structure with observations for all measurement epochs
%   allSettings         - configuration parameters
%
% Returns:
%   obsData             - structure with observations for all measurement epochs
%   nrOfEpochs          - Total number of epochs to process
%   startSampleCount    - Sample count for first epoch
%   navData             - Results from navigation
%   samplesPerMs        - samples per ms
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Temporary variables
startSampleCount = 0;
maxsamplecount = 0; 

% This loop finds out starting and ending sample counts
for signalNr = 1:allSettings.sys.nrOfSignals
    signal = allSettings.sys.enabledSignals{signalNr};    
    obs = obsData.(signal);   
    for channelNr = 1:obs.nrObs
        if(obs.channel(channelNr).bObsOk)
            ind = obs.channel(channelNr).firstSubFrame;

            % This finds out the channel with the latest subframe start point (sampleCount)
            if(obs.channel(channelNr).sampleCount(ind) > startSampleCount)
                startSampleCount = obs.channel(channelNr).sampleCount(ind);
            end
            
            if(obs.channel(channelNr).sampleCount(end) > maxsamplecount)
                maxsamplecount = obs.channel(channelNr).sampleCount(end);
            end
        end
    end
end

% We assume that we have the same sampling frequency for all data files 
samplesPerMs = obsData.(signal).samplesPerMs;

% We adjust the end sample count so that we have an integer number of
% epochs 
endSampleCount = floor((maxsamplecount - startSampleCount)/(samplesPerMs*allSettings.nav.navSolPeriod));
totalSampleCount = endSampleCount *(samplesPerMs*allSettings.nav.navSolPeriod);

% This is finally the max number of epochs we can processe
nrOfEpochs = totalSampleCount / (samplesPerMs*allSettings.nav.navSolPeriod);

% Adjust number of epochs if user has requested LESS epochs
if(allSettings.sys.msToProcess ~= 0)
    if(allSettings.sys.msToProcess / allSettings.nav.navSolPeriod < nrOfEpochs)
        nrOfEpochs = allSettings.sys.msToProcess / allSettings.nav.navSolPeriod;
    end
end

% Get the index for each channel with the closest sample count to the
% starting sample count
for signalNr = 1:allSettings.sys.nrOfSignals
    signal = allSettings.sys.enabledSignals{signalNr};        
    obs = obsData.(signal);
    for channelNr = 1:obs.nrObs
        if(obs.channel(channelNr).bObsOk)
            diff = obs.channel(channelNr).sampleCount - startSampleCount;
            [Y,I] = sort(abs(diff));
            obs.channel(channelNr).channelStartIndex = min(I(1),I(2));        
        end
    end
    obsData.(signal) = obs;
end

% Init navData structure
navData.Pos.xyz  = zeros(1,3);
navData.Pos.enu = zeros(1,3);
navData.Pos.lla = zeros(1,3);
navData.Pos.fom = NaN;
navData.Pos.dop = zeros(1,5);
navData.Pos.trueRange = NaN;
navData.Pos.rangeResid = NaN;
navData.Pos.nrSats = NaN;
navData.Pos.dt = NaN;
navData.Pos.bValid = false;
navData.Pos.Flag = NaN;

navData.Vel.xyz = zeros(1,3);
navData.Vel.fom = NaN;
navData.Vel.dopplerResid = NaN;
navData.Vel.nrSats = 0;
navData.Vel.df = NaN;
navData.Vel.bValid = false;

navData.Time.receiverTow = NaN;




