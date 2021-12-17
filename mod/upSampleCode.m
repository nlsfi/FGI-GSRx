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
function upsampledCode = upSampleCode(codeReplica,signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function upsample the modulated PRN code to sampling frequency.
%
% Inputs:
%   codeReplica             - Modulated code replica
%   signalSettings          - Settings for one signal
%
% Outputs:
%   upsampledCode          - Upsampled modulated code replica
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Find number of samples per spreading code
samplesPerCode = signalSettings.samplesPerCode;
modCodeLengthInChips = signalSettings.codeLengthInChips * signalSettings.modulationFactor;
modCodeFreqBasis = signalSettings.codeFreqBasis * signalSettings.modulationFactor;
 
% Find time constants 
ts = 1/signalSettings.samplingFreq;   % Sampling period in sec
tc = 1/modCodeFreqBasis;  % Modulated Galileo E1 chip period in sec (it is half of the unmodulated Galileo E1 chip period)

codeValueIndex = ceil((ts * (1:samplesPerCode)) / tc); 
codeValueIndex(end) = modCodeLengthInChips;

upsampledCode = zeros(size(codeReplica,1),samplesPerCode);
for codeIndex = 1:size(codeReplica,1)
    % Make the digitized version of the C/A code
    upsampledCode(codeIndex,:) = codeReplica(codeIndex,codeValueIndex);     
end
