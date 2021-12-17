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
function [obs, eph]= doFrameDecoding(obs, tR, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes input of tracking results and performs data frame
% decoding
%
% Inputs:
%   obs             - Observation for all signals
%   tR              - Tracking results for all signals
%   allSettings    - Receiver settings
%
% Outputs:
%   obs             - Observation for all signals
%   eph             - Ephemeris data for all signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over all signals
for signalIndex = 1:allSettings.sys.nrOfSignals    
    % Extract block of parameters for one signal from settings
    signal = allSettings.sys.enabledSignals{signalIndex};
    signalSettings = allSettings.(signal);

    % Find preamble positions 
    [obs.(signal)] = findPreambles(tR.(signal), obs.(signal), signalSettings);
    
    %%Consistency check whether all the subframes point to the same subframe beginning 
    for channelNr = 1:tR.(signal).nrObs
        firstSubFrames(channelNr) = obs.(signal).channel(channelNr).firstSubFrame;
    end
    [maxVal maxInd] = max(firstSubFrames);
    [minVal minInd] = min(firstSubFrames);
    if (max(firstSubFrames)-min(firstSubFrames))>=signalSettings.preambleIntervall %subFrame/page length of each system, for Galileo it is 250 symbols
        indices = find((max(firstSubFrames)-firstSubFrames)>=signalSettings.preambleIntervall);
        firstSubFrames(indices) = firstSubFrames(indices)+signalSettings.preambleIntervall;
        for channelNr = 1:tR.(signal).nrObs
           obs.(signal).channel(channelNr).firstSubFrame = firstSubFrames(channelNr);
        end
    end
    clear firstSubFrames;
    eph.(signal) = [];
    % Loop over all channels
    for channelNr = 1:obs.(signal).nrObs
        if(obs.(signal).channel(channelNr).bPreambleOk)

            obs.(signal).channel(channelNr).signal = signal;                
            prn = obs.(signal).channel(channelNr).SvId.satId;            
            % Set signal specific functions
            parityFunc = str2func([signalSettings.signal,'NavParityCheck']);
            ephFunc = str2func([signalSettings.signal,'DecodeEphemeris']);

            parityCheck = true;
            % TBA. Move parity checking to proper place for each signal
            for i=0:9
                parity(i+1) = parityFunc(tR.(signal).channel(channelNr), obs.(signal).channel(channelNr).firstSubFrame,i+1);

                if(parity(i+1) == 0)
                    disp('Parity check failed !');
                    parityCheck = false;
                    break;
                    %return;
                end                
            end

            % Decode ephemerides
            [e(prn), obs.(signal).channel(channelNr)] = ephFunc(obs.(signal).channel(channelNr), [tR.(signal).channel(channelNr).I_P], prn, signalSettings, allSettings.const);


            if parityCheck == false            
                % Now we know wheterh parity is ok or not            
                obs.(signal).channel(channelNr).bParityOk = false; 
                obs.(signal).channel(channelNr).bEphOk = false; 
            else
                obs.(signal).channel(channelNr).bParityOk = true;
            end
            
            % Set observation to valid when ephemeris has been obtained
            if obs.(signal).channel(channelNr).bEphOk==0 
                obs.(signal).channel(channelNr).bObsOk = false;
            else
                obs.(signal).channel(channelNr).bObsOk = true;
            end
            obs.(signal).channel(channelNr).firstSubFrame=obs.(signal).channel(channelNr).firstSubFrame*obs.(signal).codeLengthInMs; %% ZB: required to multiply by codeLengthInMs; because the index is generated considering the code length duration as 1 epoch
        end
    end   
    if(exist('e'))
        eph.(signal) = e;
        clear e;
    end
end
