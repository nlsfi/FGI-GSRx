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
function [modCodeReplica] = gpsl1cPModulatePrnCode(codeReplica,signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function adds a subcarrier modulation to the GPS L1C pilot code
%
% Inputs:
%   codeReplica             - Unmodulated code replica
%   signalSettings          - Settings for one signal
%
% Outputs:
%   modCodeReplica          - Modulated code replica
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (strcmp(signalSettings.modType,'TMBOC'))
    periodLengthInChips = 33;                   % TMBOC period length in chips
    N = signalSettings.codeLengthInChips / periodLengthInChips;  % Number of TMBOC periods in one bit
    mf = 12;                                    % Modulation factor
    
    % Initialize TMBOC modulation vector
    TMBOC = ones(1,periodLengthInChips*mf);
    
    % Set chips 1, 5, 7 and 30 to have BOC(6,1) modulation and rest BOC(2,1)
    for i = 1:periodLengthInChips
        if i == 1 || i == 5 || i == 7 || i == 30
            for j = 1:mf
                TMBOC((i-1)*mf + j) = -sign(sin(12*pi*j/mf));
            end
        else
            for j = 1:mf
                TMBOC((i-1)*mf + j) = -sign(sin(2*pi*j/mf));
            end
        end
    end
    
    % Generate code for pilot channel
    code_up_TMBOC=kron(codeReplica,ones(1,mf));
    TMBOC_symbol_up=repmat(TMBOC,1,N);
    modCodeReplica = code_up_TMBOC.*TMBOC_symbol_up;
else
    % Lower order BOC component: SinBOC(1,1) component for GPSL1Cp
    N_BOC11=2; % BOC order is 2
    BOC11_symbol=kron(ones(1,N_BOC11/2),[-1 1]);  
    
    % Generate code for pilot channel
    code_up_BOC11=kron(codeReplica,ones(1,N_BOC11));
    BOC11_symbol_up=repmat(BOC11_symbol,1,signalSettings.codeLengthInChips);
    modCodeReplica = code_up_BOC11.*BOC11_symbol_up;
end