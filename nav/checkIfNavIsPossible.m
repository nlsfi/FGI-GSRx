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
function trynav = checkIfNavIsPossible(obs, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Check if we have enough observations to navigate
%
% Inputs: 
%   obs             - Observations structure
%   allSettings     - receiver settings.
%
% Outputs:
%   trynav    - True if we can attempt to navigate. Othervise false. 
%
%   With one system we have 4 unknowns so we need 4 observations
%   With two systems we have 5 unknown so we need 5 observations 
%  (3+2 or 4+1)
%   
%   With three systems we have 6 unknowns so we need 6 observations
%   (2+2+2) or (3+2+1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Assume false
trynav = false;

% Loop over all signals
for signalNr = 1:allSettings.sys.nrOfSignals
        
    % Extract signal acronym
    signal = allSettings.sys.enabledSignals{signalNr};
    
    % Reset temporary variable
    validObs(signalNr) = 0;
    
    % Calculate valid observations
    for channelNr = 1:obs.(signal).nrObs
        if(obs.(signal).channel(channelNr).bObsOk)
            validObs(signalNr) = validObs(signalNr) + 1;
        end
    end
end

% We can not navigate unless we have at least 2 observations from any system
if(max(validObs) < 2)
    return; 
end

% We need to count number of satellites for all signals - 1
% observations/signal for all signals except one (one observation is needed
% to get the clock offset compared to the other signals). 
numberOfUsefullObservations = sum(validObs) - length(validObs) + 1;

% We can not navigate unless we have at least 2 observations from any system
if(numberOfUsefullObservations < 4)
    return; 
end

% If we end up here we can navigate
trynav = true;


