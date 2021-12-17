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
function obs = checkObservations(obs,sat,allSettings,navSolution)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function decides which observations are going to be used in
% navigation
%
% Inputs:
%   obs             - structure with observations for one measurement epochs
%   sat             - structure with satellite info for one epochs
%   allSettings     - configuration parameters
%   navSolutions    - Output from navigation (position, velocity, time,
%
% Outputs:
%   obs             - structure with observations for one measurement epochs
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% We need user position to do anything
if(strcmp(navSolution.Pos.Flag,'GOOD_FOR_NAV') == 0)
    return;
end

% Loop over all signals
for signalNr = 1:allSettings.sys.nrOfSignals
        
    % Extract signal acronym
    signal = allSettings.sys.enabledSignals{signalNr};
    
    % Loop over all channels
    for channelNr = 1:obs.(signal).nrObs
        if(obs.(signal).channel(channelNr).bObsOk)
            if((sat.(signal).channel(channelNr).elev < allSettings.nav.elevationMask))
                obs.(signal).channel(channelNr).bObsOk = false;
            end            
    %SNR limit        
            if(obs.(signal).channel(channelNr).SNR < allSettings.nav.snrMask)
                obs.(signal).channel(channelNr).bObsOk = false;
            end            
        end
    end
end





