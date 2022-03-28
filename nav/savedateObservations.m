%%  delete the struct for save little data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function saveobs = savedateObservations(obs,allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function updates the observations with results after navigation is
% available
%
% Inputs:
%   obs             - Structure with current observation (one)
%   Pos             - Structure with current position
%   Vel             - Structure with current velocity
%   allSettings     - configuration parameters
%
% Outputs:
%   obs             - Structure with current observation (one)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ind = 1;
saveobs = obs;
% Loop over all signals
for signalNr = 1:allSettings.sys.nrOfSignals
        
    % Extract signal acronym
    signal = allSettings.sys.enabledSignals{signalNr};    
    
    % Loop over all channels
    for channelNr = 1:obs.(signal).nrObs
        saveobs.(signal).channel(channelNr).sampleCount = [];
        saveobs.(signal).channel(channelNr).CN0         = [];
        saveobs.(signal).channel(channelNr).carrFreq    = [];
        saveobs.(signal).channel(channelNr).codePhase   = [];
    end
end