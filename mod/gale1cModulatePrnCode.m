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
function [modCodeReplica,signalSettings] = gale1cModulatePrnCode(codeReplica,signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function adds a subcarrier modulation to the Galileo code
%
% Inputs:
%   codeReplica             - Unmodulated code replica
%   signalSettings          - Settings for one signal
%
% Outputs:
%   modCodeReplica          - Modulated code replica
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Lower order BOC component: SinBOC(1,1) component for Galileo E1
N_BOC11=2; % BOC order is 2
BOC11_symbol=kron(ones(1,N_BOC11/2),[1 -1]);  

% Generate code for pilot channel
code_up_BOC11=kron(codeReplica,ones(1,N_BOC11));
BOC11_symbol_up=repmat(BOC11_symbol,1,signalSettings.codeLengthInChips);
modCodeReplicaBOC11 = code_up_BOC11.*BOC11_symbol_up;

if (strcmp(signalSettings.modType,'CBOC')==1)
    % Higher order BOC Component: SinBOC(6,1) for Galileo E1C
    N_BOC61=12; % BOC order is 12
    BOC61_symbol=kron(ones(1,N_BOC61/2),[1 -1]); 

    % Generate code for pilot channel
    code_up_BOC61=kron(codeReplica,ones(1,N_BOC61));
    BOC61_symbol_up=repmat(BOC61_symbol,1,signalSettings.codeLengthInChips);
    modCodeReplicaBOC61 = code_up_BOC61.*BOC61_symbol_up;

    BOCOrderRatio = N_BOC61/N_BOC11;

    modCodeReplicaBOC11_up = kron(modCodeReplicaBOC11,ones(1,BOCOrderRatio));
    modCodeReplica = sqrt(10/11)*modCodeReplicaBOC11_up  - sqrt(1/11)*modCodeReplicaBOC61; %CBOC(-) implementatin for pilot channel
else
    modCodeReplica = modCodeReplicaBOC11;
end
 











