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
function tR = getFreqPlanParameters(tR, signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialises signal independent tracking data
%
% Inputs:
%   tR               - Results from signal tracking for one signals
%   signalSettings   - receiver settings for one signal 
%
% Outputs:
%   tR               - Results from signal tracking for one signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tR.complexData = signalSettings.complexData;
tR.iqSwap = signalSettings.iqSwap;
tR.centerFrequency = signalSettings.centerFrequency;
tR.bandWidth = signalSettings.bandWidth;
tR.sampleSize = signalSettings.sampleSize;
tR.samplingFreq = signalSettings.samplingFreq;
tR.samplesPerChip = signalSettings.samplesPerChip;
tR.samplesPerCode = signalSettings.samplesPerCode;

if(tR.complexData == true)
    tR.samplesPerRead = 0.5;
    tR.dataType = strcat('int',num2str(tR.sampleSize/2));
else
    tR.samplesPerRead = 1;
    tR.dataType = strcat('int',num2str(tR.sampleSize));
end

tR.codeLengthInChips = signalSettings.codeLengthInChips;
tR.codeLengthInMs = signalSettings.codeLengthMs; 

tR.codeFreqBasis = signalSettings.codeFreqBasis;
tR.secondaryCode = signalSettings.secondaryCode;

tR.modulationFactor = signalSettings.modulationFactor;




