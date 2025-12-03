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
function obs = applyObservationCorrections(allSettings, obs, sat, navSolution,corrInputData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main function for applying all corrections to the pseudoranges
% and dopplers
%
% Inputs:
%   allSettings     - receiver configuration settings
%   obs             - Observations for one epoch
%   sat             - satellite positions and velocities for one epoch
%   navSolutions    - Output from navigation (position, velocity, time,
%
% Outputs:
%   obs             - Observations for one epoch
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over all signals
for signalNr = 1:allSettings.sys.nrOfSignals
        
    % Extract signal acronym
    signal = allSettings.sys.enabledSignals{signalNr};
    
    % Extract block of parameters for one signal from settings
    param = allSettings.(signal);
    
    % Temporary variable for receiver time for one signal    
    refTime = obs.(signal).receiverTow; 
    
    % For GLONASS, time has to be shifted from UTC+3 to UTC
    if (strcmp(signal, 'glol1'))
        refTime = mod(refTime - 10800, 86400);
    end    

    % Apply corrections
    for channelNr = 1:obs.(signal).nrObs
        if(obs.(signal).channel(channelNr).bObsOk)
            satSingle = sat.(signal).channel(channelNr);
            obs.(signal).channel(channelNr) = ...
                applyClockCorrections(allSettings.const, obs.(signal).channel(channelNr), satSingle);
            
            obs.(signal).channel(channelNr) = ...
                applyTropoCorrections(allSettings.const, param, obs.(signal).channel(channelNr), satSingle, navSolution);

            obs.(signal).channel(channelNr) = ...
                applyIonoCorrections(param, allSettings.const, obs.(signal).channel(channelNr), satSingle, navSolution, refTime,corrInputData.iono.(param.ionomodel));
            
        end
    end
end








