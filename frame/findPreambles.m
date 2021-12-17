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

% Generate the preamble pattern 
preamble_bits = signalSettings.preamble;

% "Upsample" the preamble - make 20 values per one bit. The preamble must be
% found with precision of a sample.
preamble_ms = kron(preamble_bits, signalSettings.secondaryCode);
preambleInterval = signalSettings.preambleIntervall;
preambleCorrThr = signalSettings.preambleCorrThr;
% Loop over all tracking channels
for k=1:tR.nrObs

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

    %Correlate tracking output with the preamble
    tlmXcorrResult = calcCrossCorrelation(navigationBits, preamble_ms);
    
    tm_bits = [-1 1 1 -1 1 -1 -1 1 -1 -1 -1 -1 1 -1 1 -1 1 1 1 -1 1 1 -1 -1 -1 1 1 1 1 1]; 
    tm_long = kron(-tm_bits, ones(1,10)); 
    tm_corr_rslt = conv(tm_long, navigationBits);
    tm_corr_rslt = tm_corr_rslt(300:length(tm_corr_rslt)); %First 300 points are not considered as tracking require some time to settle in at Fine Tracking stage

    % Find all starting points of all preamble like patterns 
    clear index
    xcorrLength = (length(tlmXcorrResult) +  1) /2;
    index = find(abs(tlmXcorrResult(xcorrLength : xcorrLength * 2 - 1)) >= preambleCorrThr)' + searchStartOffset;    
    
    if (~isempty(index))
        for i = 1:length(index)
            indexVerification = find(mod(index-index(i),preambleInterval)==0); % Nr of values spaced by a multiple of 250
            cnt = size(indexVerification,1);
            
            % we have at least 6 matching indexes
            if (cnt > 5)

                % Check parity
                codeFunc = str2func([signalSettings.signal,'NavParityCheck']);
                parityCheck1 = codeFunc(tR.channel(k), index(i),1);
                parityCheck2 = codeFunc(tR.channel(k), index(i),2);
                
                if ((parityCheck1 ~= 0) && (parityCheck2 ~= 0))
                    % At this stage, parity check is successful. Preamble start position is recorded.
                    obs.channel(k).firstSubFrame = index(i);
                    obs.channel(k).bPreambleOk = true;
                    disp(['Preamble found for ', obs.signal ,' prn ', num2str(obs.channel(k).SvId.satId),' !'])              
                    break;                   
                end

           end
        end            
    end    

    %Report if no preamble is found
    if (isnan(obs.channel(k).firstSubFrame))
        disp(['Could not find valid preambles for ', obs.signal ,' prn ', ...
            num2str(obs.channel(k).SvId.satId),' !'])  
    end
end