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
function [obs] = findPreambles(tR, obs, signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Finds the first preamble occurrence in the bit stream of
% each channel. The preamble is verified by check of the spacing between
% preambles 
%
% Inputs:
%   tR              - Tracking results for one signal
%   obs             - Observations for one signals
%   signalSettings  - Receiver settings for one signal
%
% Outputs:
%   obs             - Observations for one signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Preamble search can be delayed to a later point in the tracking results
% to avoid noise due to tracking loop transients 
searchStartOffset = 0;

% Loop over all tracking channels
for k=1:tR.nrObs
    % Generate the preamble pattern
    if strcmp(signalSettings.signal,'gpsl1c')==1
        preamble_bits = gpsl1cGenerateOverlay(tR.channel(k).SvId.satId);
    else
        preamble_bits = signalSettings.preamble;
    end
    % "Upsample" the preamble - make 20 values per one bit. The preamble must be
    % found with precision of a sample.
    preamble_ms = kron(preamble_bits, signalSettings.secondaryCode);
    preambleInterval = signalSettings.preambleIntervall;
    preambleCorrThr = signalSettings.preambleCorrThr;

    if strcmp(signalSettings.signal,'beib1')==1
        if tR.channel(k).SvId.satId<6
            secondaryCode = [1 1];  %%As one data bit lasts for 2 msec for GEO satellites and does not have any NH code modulation
            clear preamble_ms;
            preamble_ms = kron(preamble_bits, secondaryCode);
            preambleInterval = 600; %% Preamble interval for GEO satellites is 0.6 seconds
            preambleCorrThr = 20; %%%% Preamble correlation threshold for GEO satellites (10 times less than MEO)
        else
            clear preamble_ms;
            preamble_ms = kron(preamble_bits, signalSettings.secondaryCode);
            preambleInterval = signalSettings.preambleIntervall;
            preambleCorrThr = signalSettings.preambleCorrThr;
        end        
    end
    % Decode navigation bits from tracking prompt finger. 
    navigationBits = tR.channel(k).I_P(signalSettings.codeLengthMs + searchStartOffset : ...
        signalSettings.codeLengthMs : end);

    % Convert the correlation output to +1 and -1 
    navigationBits(navigationBits > 0)  =  1;
    navigationBits(navigationBits <= 0) = -1;

    %Consider processing first few messages within one minute or so:
    %specially helpful for long data set
    firstNbits = navigationBits(1:min(preambleInterval*10,length(navigationBits)));

    %Correlate tracking output with the preamble
    tlmXcorrResult = calcCrossCorrelation(firstNbits, preamble_ms);

    % Find all starting points of all preamble like patterns 
    clear index
    xcorrLength = (length(tlmXcorrResult) +  1) /2;
    index = find(abs(tlmXcorrResult(xcorrLength : xcorrLength * 2 - 1)) >= preambleCorrThr)' + searchStartOffset;    
    
    if (~isempty(index))
        for i = 1:length(index)
            indexVerification = find(mod(index-index(i),preambleInterval)==0); % Nr of values spaced by a multiple of 250
            cnt = size(indexVerification,1);
            %Estimate possible number of preambles in the sucessfully converted data stream
            possibleNrOfPreambleOccurance = floor(length(firstNbits)/(preambleInterval))-3; %Use some protection for transition from FLL to PLL (usually couple of seconds shoudl be fine)
            % we have at least 6 matching indexes
            if (cnt >=  (possibleNrOfPreambleOccurance-1)) && index(i)>preambleInterval % Do not consider the first index within the first second of data processing
                
                % Check parity
                codeFunc = str2func([tR.signal,'NavParityCheck']);
                parity1 = codeFunc(tR.channel(k), index(i),1);
                parity2 = codeFunc(tR.channel(k), index(i),2);
                
                if ((parity1 ~= 0) && (parity2 ~= 0))
                    % Parity was OK. Record the preamble start position. Skip
                    % the rest of preamble pattern checking for this channel
                    % and process next channel.
                    obs.channel(k).firstSubFrame = index(i);
                    obs.channel(k).preambleSign = sign(tlmXcorrResult(index(i) + xcorrLength - 1));
                    obs.channel(k).bPreambleOk = true;
                    
                    if strcmp(signalSettings.signal,'navicl5')==1
                        disp(['Sync Word found for ', obs.signal ,' prn ', ...
                            num2str(obs.channel(k).SvId.satId),' !'])
                    else
                        disp(['Preamble found for ', obs.signal ,' prn ', ...
                            num2str(obs.channel(k).SvId.satId),'!'])
                    end                    
                    break;
                end
                
            end
        end
    end
    % Report if no preamble was found
    if (isnan(obs.channel(k).firstSubFrame))
        disp(['Could not find valid preambles for ', obs.signal ,' prn ', ...
            num2str(obs.channel(k).SvId.satId),'!'])
    end
end