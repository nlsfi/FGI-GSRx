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
function [modCodeReplica,signalSettings] = beib1ModulatePrnCode(codeReplica,signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function adds the Neumann-Hoffman modulation to the BeiDou GEO 
% satellites PRN codes.
%
% Inputs:
%   codeReplica             - Unmodulated code replica
%   signalSettings          - Settings for one signal
%
% Outputs:
%   modCodeReplica          - Modulated code replica
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TBA GEO satellites

% if PRN > 5 % For MEO/IGSO satellites, Neumann-Hoffman modulation
%     NH = 2*[0 0 0 0 0 1 0 0 1 1 0 1 0 1 0 0 1 1 1 0]-1;
%     code_up = repmat(code,1,length(NH));
%     NH_up = kron(NH,ones(1,length(code)));
%     modCode = NH_up.*code_up;  % 20ms long code
%     settings.samplesPerCode = settings.samplesPerCode*length(NH);
%     settings.modCodeLengthMs = settings.codeLengthMs*length(NH);
%     settings.modCodeLengthChips = settings.codeLengthChips*length(NH);
%     settings.modCodeFreqBasis = settings.codeFreqBasis;
%     settings.bitDuration = 1;
% else

    % No Code modulation for Beidou B1 Geo satellites
    modCodeReplica = codeReplica;
