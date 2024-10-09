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
function [modCodeReplica] = gpsl1cDModulatePrnCode(codeReplica,signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function adds a subcarrier modulation to the GPS L1C data code
%
% Inputs:
%   codeReplica             - Unmodulated code replica
%   signalSettings          - Settings for one signal
%
% Outputs:
%   modCodeReplica          - Modulated code replica
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TMBOC option is currently not needed but included for possible future use; matches upsampling rate with the pilot channel
if (strcmp(signalSettings.modType,'TMBOC')) 
    % Lower order BOC component: SinBOC(1,1) component for GPSL1Cd
    N_BOC11=12; % BOC order is 12 as the code is upsampled
    BOC11_symbol= [-1 -1 -1 -1 -1 -1 1 1 1 1 1 1];  
    
    % Generate code for pilot channel
    code_up_BOC11=kron(codeReplica,ones(1,N_BOC11));
    BOC11_symbol_up=repmat(BOC11_symbol,1,signalSettings.codeLengthInChips);
    modCodeReplica = code_up_BOC11.*BOC11_symbol_up;
else
    % Lower order BOC component: SinBOC(1,1) component for GPSL1Cd
    N_BOC11=2; % BOC order is 2
    BOC11_symbol=kron(ones(1,N_BOC11/2),[-1 1]);  
    
    % Generate code for pilot channel
    code_up_BOC11=kron(codeReplica,ones(1,N_BOC11));
    BOC11_symbol_up=repmat(BOC11_symbol,1,signalSettings.codeLengthInChips);
    modCodeReplica = code_up_BOC11.*BOC11_symbol_up;
end