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
function tC = getCorrelatorFingers(tC,allSettings,signal)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copy correlator finger configuration to tracking structure
%
% Inputs:
%   tC           - Results from signal tracking for one channel
%   fingerParams - settings with finger configuration 
%
% Outputs:
%   tC           - Results from signal tracking for one channel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tC.corrFingers = allSettings.(signal).corrFingers;
tC.earlyFingerIndex = allSettings.(signal).earlyFingerIndex;
tC.promptFingerIndex = allSettings.(signal).promptFingerIndex;
tC.lateFingerIndex = allSettings.(signal).lateFingerIndex;
tC.noiseFingerIndex = allSettings.(signal).noiseFingerIndex;
tC.corrFingersOut = zeros(1,length(tC.corrFingers));
dataLength = allSettings.sys.msToProcess - allSettings.sys.msToSkip;
if (allSettings.sys.enableMultiCorrelatorTracking == true)
    tC.mulCorrFingers = allSettings.sys.mulCorrFingers;
    tC.mulCorrFingersOut = zeros(dataLength,length(allSettings.sys.mulCorrFingers));
end





