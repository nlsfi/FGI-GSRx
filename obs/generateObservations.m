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
function  obsResults = generateObservations(tR, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes input of tracking results and generates
% observations for the navigation
%
% Inputs:
%   tR              - tracking results 
%   allSettings     - Receiver settings
%
% Outputs:
%   obsResults      - Observations for the navigation
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over all enabled signals
for signalIndex = 1:allSettings.sys.nrOfSignals
    
    % Extract block of parameters for one signal from settings
    signal = allSettings.sys.enabledSignals{signalIndex};
    param = allSettings.(signal);
    
    obsResults.(signal).samplesPerMs = param.samplingFreq/1000; 

    % Estimated traveltime from satellite to user in ms. Same for all GNSS. 
    % This is needed to form PR, both the value is not critical.
    % This is whi it is called pseudo range and not range
    obsResults.(signal).averagetraveltime = 80; 

    obsResults.(signal).codeLengthInMs = tR.(signal).codeLengthInMs; 
    obsResults.(signal).codeFreqBasis = tR.(signal).codeFreqBasis; 
    obsResults.(signal).nrObs = tR.(signal).nrObs;
    obsResults.(signal).signal = tR.(signal).signal;

    % Copy channel specific data
    for i=1:tR.(signal).nrObs
        obsResults.(signal).channel(i).carrierFreq = tR.(signal).channel(i).carrierFreq; 
        obsResults.(signal).channel(i).sampleCount = tR.(signal).channel(i).absoluteSample;
        obsResults.(signal).channel(i).SvId = tR.(signal).channel(i).SvId;
        obsResults.(signal).channel(i).CN0 = tR.(signal).channel(i).meanCN0fromSNR;
        obsResults.(signal).channel(i).carrFreq = tR.(signal).channel(i).carrFreq - tR.(signal).channel(i).intermediateFreq;
        obsResults.(signal).channel(i).sampleCount = tR.(signal).channel(i).absoluteSample;
        obsResults.(signal).channel(i).codePhase = tR.(signal).channel(i).codePhase;

        obsResults.(signal).channel(i).receiverTow = NaN;
        obsResults.(signal).channel(i).week = NaN;

        obsResults.(signal).channel(i).firstSubFrame = NaN;
        obsResults.(signal).channel(i).bPreambleOk = false;        
        obsResults.(signal).channel(i).bParityOk = false;        
        obsResults.(signal).channel(i).bEphOk = false;
        obsResults.(signal).channel(i).bObsOk = false;        
        obsResults.(signal).channel(i).tow = NaN;        
        obsResults.(signal).channel(i).transmitTime = NaN;        
        obsResults.(signal).channel(i).codephase = NaN;    
        obsResults.(signal).channel(i).doppler = NaN;    
        obsResults.(signal).channel(i).channelStartIndex = NaN; 
        obsResults.(signal).channel(i).clockCorr = NaN; 
        obsResults.(signal).channel(i).ionoCorr = NaN;     
        obsResults.(signal).channel(i).tropoCorr = NaN;     
        obsResults.(signal).channel(i).rawP = NaN;
        obsResults.(signal).channel(i).corrP = NaN;         

        obsResults.(signal).channel(i).trueRange = NaN;
        obsResults.(signal).channel(i).rangeResid = NaN;
        obsResults.(signal).channel(i).dopplerResid = NaN;
    end
end



