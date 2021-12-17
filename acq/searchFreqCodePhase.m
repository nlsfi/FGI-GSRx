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
function searchResults = searchFreqCodePhase( codeReplica, signalSettings, pRfData, PRN )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function performs the parallel code phase search acquisition 
% for a given satellite signal
%
% Inputs: 
%   codeReplica         - locally generated code replica
%   signalSettings      - Settings for one signal
%   pRfData             - RF data from file
%   PRN                 - Signal identifier
%
% Outputs:
%   searchResults       - Results from the parallel code phase search
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set local variables
samplesPerCode = signalSettings.samplesPerCode;  % Number of samples per spreading code                    
cohIntNumber = signalSettings.cohIntNumber;
nonCohIntNumber = signalSettings.nonCohIntNumber; 
freqWindow = signalSettings.maxSearchFreq; % One sided
centerFreq = signalSettings.intermediateFreq + (PRN-8)*signalSettings.frequencyStep;
codeLengthMs = signalSettings.codeLengthMs; 

% Sampling period
ts = 1 / signalSettings.samplingFreq;

% Number of the frequency bins for the given acquisition band
freqStep = 1000/(2*codeLengthMs*cohIntNumber);
    
% Number of the frequency bins for the given acquisition band (500Hz steps)
numberOfFrqBins = floor(2 * freqWindow/freqStep + 1);

% Allocate variables
frqBins = zeros(1, numberOfFrqBins); % Carrier frequencies of the frequency bins
searchResults = zeros(numberOfFrqBins,samplesPerCode); % Results structure
            
% Find phase points of the local carrier wave 
phasePoints = (0 : (cohIntNumber*samplesPerCode-1)) * 2 * pi * ts;  

% Loop over frequency bins
for frqBinIndex = 1:numberOfFrqBins    
     
    % Reset sum of all signals 
    sumNonCohAllSignals = zeros(1,samplesPerCode);
    
    % Loop over number of codes (pilot, data)
    for codeIndex = 1:size(codeReplica,1)  
        
        % Perform FFT on upsampled code
        codeFreqDom =  conj(fft(codeReplica(codeIndex,:)));
        
        % Calculate frequency of search bin
        frqBins(frqBinIndex) = centerFreq - ...
                               freqWindow + ...
                               freqStep * (frqBinIndex - 1);    
        
        % Generate local carrier frequency for bin  
        sigCarr = exp(-1i*frqBins(frqBinIndex) * phasePoints);   
        
        % Reset sum of non coherent integration of one signal  
        sumNonCoh=zeros(1,samplesPerCode);
        
        % Reset variable for signal
        signal = zeros(nonCohIntNumber,cohIntNumber*samplesPerCode);
        
        % Loop over all non coherent rounds
        for nonCohIndex=1:nonCohIntNumber
            
            % Extract needed part of signal
            signal(nonCohIndex,:) = pRfData((nonCohIndex-1)*cohIntNumber*samplesPerCode+1:nonCohIndex*cohIntNumber*samplesPerCode);
            
            % Mix with carrier replica
            IQ = sigCarr .* signal(nonCohIndex,:);
  
            % Reste sum of coherent integration
            sumCoh=zeros(1,samplesPerCode);
            
            % Coherent integration
            for cohIndex=1:cohIntNumber                                             
                
                % FFT of signal mixed with carrier 
                IQ_fft = fft(IQ((cohIndex-1)*samplesPerCode+1:cohIndex*samplesPerCode));
                
                % Inverse FFT of code times signal+carrier 
                sumCoh = sumCoh+ifft(IQ_fft.*codeFreqDom);

            end % End coherent integration
            
            % Non coherent integration. Accumulate results.
            sumNonCoh=sumNonCoh+abs(sumCoh);           
            
        end % End non coherent integration
        
        % Add results from all signals (pilot, data)
        sumNonCohAllSignals = sumNonCohAllSignals + sumNonCoh;
        
    end
    
    % Copy final result for current frequency bin
    searchResults(frqBinIndex,:)=sumNonCohAllSignals;    
end % End frequency bin search
