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
function acqResults = initAcquisition(allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function initialises the acquisition structure
%
% Inputs: 
%   allSettings         - Receiver settings
%
% Outputs:
%   acqResults          - Acquisition results
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:allSettings.sys.nrOfSignals
    signal = allSettings.sys.enabledSignals{i};
    len = length(allSettings.(signal).acqSatelliteList);
    acqResults.(signal).signal = signal;
    acqResults.(signal).nrObs = len;
    acqResults.(signal).duration = 0;
    for k=1:len
        acqResults.(signal).channel(k).peakMetric = 0;
        acqResults.(signal).channel(k).peakValue = 0;
        acqResults.(signal).channel(k).variance = 0;
        acqResults.(signal).channel(k).baseline = 0;
        acqResults.(signal).channel(k).bFound = 0;
        acqResults.(signal).channel(k).carrFreq = 0;
        acqResults.(signal).channel(k).codePhase = 0;
        acqResults.(signal).channel(k).SvId = getSvId(signal,allSettings.(signal).acqSatelliteList(k));
        acqResults.(signal).channel(k).spec = zeros(1,allSettings.(signal).samplesPerCode);
    end
    
end

