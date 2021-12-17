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
function [obs] = getTransmitTime(obs,samplecnt,allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Get the transmission time for each channel for a given target sample
% count
%
% Inputs:
%   obs             - Observations for current epoch
%   samplecnt       - current sample count
%   allSettings     - configuration parameters
%
% Outputs:
%   obs             - Observations for current epoch
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Constant
SPEED_OF_LIGHT = allSettings.const.SPEED_OF_LIGHT;

% Loop over all signals
for signalNr = 1:allSettings.sys.nrOfSignals
        
    % Extract block of parameters for one signal from settings
    signal = allSettings.sys.enabledSignals{signalNr};    

    % Loop over all channels for one signal
    for channelNr = 1:obs.(signal).nrObs
        if(obs.(signal).channel(channelNr).bEphOk)
            obs.(signal).channel(channelNr).bObsOk = true;
            stepsize = obs.(signal).codeLengthInMs;
            codephasecoeff = obs.(signal).codeFreqBasis;
            
            % Optimization: store the previous found value of channelStartIndex
            % to speed up the following epoch
            if ~isfield( obs.(signal).channel(channelNr), 'prevStartIndex' ) ...
               || isempty( obs.(signal).channel(channelNr).prevStartIndex )
                channelStartIndex = obs.(signal).channel(channelNr).channelStartIndex;
            else
                channelStartIndex = obs.(signal).channel(channelNr).prevStartIndex;
            end
            
            % Let's start with the next sample count
            samplecount = obs.(signal).channel(channelNr).sampleCount(channelStartIndex); 
            
            % We need to find the sample count that is the last preceeding the target sample count
            while (samplecount < samplecnt) 
                channelStartIndex = channelStartIndex + stepsize;
                samplecount = obs.(signal).channel(channelNr).sampleCount(channelStartIndex);
            end
            
            obs.(signal).channel(channelNr).prevStartIndex = channelStartIndex;
            
            % This two are the indexes for each channel that are closest to the target sample count
            ind_min = channelStartIndex-stepsize; 
            ind_max = channelStartIndex;
            tow = obs.(signal).channel(channelNr).tow;
            
            % Number of epoch since the last decoded tow for each channel
            epoch = ind_min - obs.(signal).channel(channelNr).firstSubFrame; 
            
            phase = (samplecnt - obs.(signal).channel(channelNr).sampleCount(ind_min)) / (obs.(signal).channel(channelNr).sampleCount(ind_max) - obs.(signal).channel(channelNr).sampleCount(ind_min));
            codediff = (obs.(signal).channel(channelNr).codePhase(ind_max) - obs.(signal).channel(channelNr).codePhase(ind_min));

            obs.(signal).channel(channelNr).transmitTime = tow + epoch/1000 + stepsize * phase/1000;  
            obs.(signal).channel(channelNr).codephase = (obs.(signal).channel(channelNr).codePhase(ind_min) + codediff * phase)/codephasecoeff;         
            obs.(signal).channel(channelNr).doppler = obs.(signal).channel(channelNr).carrFreq(ind_min)...
                 * SPEED_OF_LIGHT/obs.(signal).channel(channelNr).carrierFreq;
            obs.(signal).channel(channelNr).SNR = obs.(signal).channel(channelNr).CN0(ind_min);                 
        end
    end
end

