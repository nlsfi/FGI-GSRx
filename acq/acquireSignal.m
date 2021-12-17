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
function acqResults = acquireSignal(pRfData,signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function acquires one signal (from all the given satellites)
%
% Inputs: 
%  pRfData          - RF data
%  signalSettings   - Settings for one signal
%
% Outputs:
%  acqResults       - Acquisition results
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tic;

% Print progress info
len = length(signalSettings.acqSatelliteList);
fprintf('\n%s','Acquiring ');
fprintf('%s',char(signalSettings.signal));
fprintf(' signals...');
fprintf('\n*===');
for i = 1:(len-1)
    fprintf('===');
end
fprintf('*\n');
fprintf('|');

for PRN = signalSettings.acqSatelliteList
    fprintf('%02d ', PRN);
end
fprintf('|');
fprintf('\n*===');
for i = 1:(len-1)
    fprintf('===');
end
fprintf('*\n');
fprintf('%s','Found ');
fprintf('%s',char(signalSettings.signal));
fprintf('%s',' signals:');
fprintf('\n*===');
for i = 1:(len-1)
    fprintf('===');
end
fprintf('*\n');
fprintf('|');

% Set local variables
acqThreshold = signalSettings.acqThreshold;
samplesPerCode = signalSettings.samplesPerCode;
codeLengthMs = signalSettings.codeLengthMs;
freqWindow = signalSettings.maxSearchFreq; % One sided
samplesPerCodeChip   = round(signalSettings.samplingFreq / signalSettings.codeFreqBasis);
chIndex = 1;

% Calculate frequency step for search
freqStep = 1000/(2*codeLengthMs*signalSettings.cohIntNumber);

% Perform search for all listed PRN numbers
for PRN = signalSettings.acqSatelliteList
    
    % Set local variables
     centerFreq = signalSettings.intermediateFreq + (PRN-8)*signalSettings.frequencyStep;            
    
    if (strcmp(signalSettings.signal,'gale1b')==1 || strcmp(signalSettings.signal,'gale1c') == 1)
        % Generate ranging code        
        PrnCodeE1B = gale1bGeneratePrnCode(PRN);
        PrnCodeE1C = gale1cGeneratePrnCode(PRN);
        % Add code modulation
        [modulatedCodeE1B,signalSettings] = gale1bModulatePrnCode(PrnCodeE1B, signalSettings);
        [modulatedCodeE1C,signalSettings] = gale1cModulatePrnCode(PrnCodeE1C, signalSettings);
        % Upsample code to sampling frequency
        upSampledCodeE1B = upSampleCode(modulatedCodeE1B, signalSettings);
        upSampledCodeE1C = upSampleCode(modulatedCodeE1C, signalSettings);
        % Perform the parallel code phase search 
        resultsE1B = searchFreqCodePhase(upSampledCodeE1B, signalSettings, pRfData, PRN);
        resultsE1C = searchFreqCodePhase(upSampledCodeE1C, signalSettings, pRfData, PRN);      
        results = resultsE1B + abs(resultsE1C);
    else
        % Generate ranging code
        generatePrnCodeFunc = str2func([signalSettings.signal,'GeneratePrnCode']);
        PrnCode = generatePrnCodeFunc(PRN);    
        % Add code modulation
        modulateFunc = str2func([signalSettings.signal,'ModulatePrnCode']);
        [modulatedCode,signalSettings] = modulateFunc(PrnCode, signalSettings);
        % Upsample code to sampling frequency
        upSampledCode = upSampleCode(modulatedCode, signalSettings);
        % Perform the parallel code phase search 
        results = searchFreqCodePhase(upSampledCode, signalSettings, pRfData, PRN);
    end
      
    % Find the correlation peak and the corresponding frequency bin and code phase
    [peakSize, frequencyBinIndex] = max(max(results, [], 2));
    [peakSize, codePhase] = max(results(frequencyBinIndex,:));
    
    % Find 1 chip wide code phase exclude range around the peak
    excludeRangeIndex1 = codePhase - samplesPerCodeChip;
    excludeRangeIndex2 = codePhase + samplesPerCodeChip;
    
    % Correct code phase exclude range if the range includes array boundaries
    if excludeRangeIndex1 < 2
        codePhaseRange = excludeRangeIndex2 : ...
                         (samplesPerCode + excludeRangeIndex1);
                         
    elseif excludeRangeIndex2 >= samplesPerCode
        codePhaseRange = (excludeRangeIndex2 - samplesPerCode) : ...
                         excludeRangeIndex1;
    else
        codePhaseRange = [1:excludeRangeIndex1, ...
                          excludeRangeIndex2 : samplesPerCode];
    end
    
    % Calculate baseline and variance for data outside peak
    variance = std(results(frequencyBinIndex,codePhaseRange));    
    baseline = mean(results(frequencyBinIndex,codePhaseRange));
    peakMetric = (peakSize-baseline)/variance;

    acqResults.channel(chIndex).peakMetric = (peakSize-baseline)/variance;
    acqResults.channel(chIndex).peakValue = peakSize;    
    acqResults.channel(chIndex).variance = variance;
    acqResults.channel(chIndex).baseline = baseline;
    acqResults.channel(chIndex).SvId.satId = PRN;  
    acqResults.signal = signalSettings.signal;
    acqResults.channel(chIndex).spec = results(frequencyBinIndex,:)-baseline;
    
    % Check if we have found the signal 
    if (peakMetric > acqThreshold)                        
        
        % Signal has been found 
        
        % Indicate PRN number of the detected signal 
        fprintf('%02d ', PRN);
         if (strcmp(signalSettings.signal,'gale1b')==1 || strcmp(signalSettings.signal,'gale1c') == 1)
            if max(resultsE1B(:)) > max(resultsE1C(:))
                results = resultsE1B;
            else
                results = resultsE1C;
            end
            [peakSize, frequencyBinIndex] = max(max(results, [], 2));
            [peakSize, codePhase] = max(results(frequencyBinIndex,:));
         end
       
        % Copy results
        acqResults.channel(chIndex).codePhase = codePhase;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        %%%% Update for unusual multipath dopper seen in Galileo constellation;
        %%%% The current solution now looks for multipath dopper, i.e., 
        %%%% multiple peaks in carrier domain; if they exist, the estimated 
        %%%% doppler is carefully chosen: in this case, the lowest 
        %%%% point in the valley between the two peaks
        firstMaxPeak = peakSize;
        firstMaxPeakInd = frequencyBinIndex;
        [candidatePeaksInd] = find(results(:,codePhase)>0.8*firstMaxPeak);
        candidatePeaksVal = results(candidatePeaksInd,codePhase);
        if length(candidatePeaksInd)>1
            multiplePeaksYes = 0;
            for jj=1:length(candidatePeaksInd)
                if (candidatePeaksInd(jj) ~= firstMaxPeakInd)
                    if candidatePeaksVal(jj)>results(candidatePeaksInd(jj)-1,codePhase) ...
                            && candidatePeaksVal(jj)>results(candidatePeaksInd(jj)+1,codePhase)
                        secondMaxPeak = candidatePeaksVal(jj);
                        secondMaxPeakInd = candidatePeaksInd(jj);
                        multiplePeaksYes = 1;
                    end
                end
            end
            if multiplePeaksYes == 1
                if firstMaxPeakInd<=secondMaxPeakInd
                    [minVal minInd] = min(results(firstMaxPeakInd:secondMaxPeakInd,codePhase));
                    finalFrequencyBinIndex = firstMaxPeakInd + minInd -1;
                else
                    [minVal minInd] = min(results(secondMaxPeakInd:firstMaxPeakInd,codePhase));
                    finalFrequencyBinIndex = secondMaxPeakInd + minInd -1;
                end
            else
                finalFrequencyBinIndex = frequencyBinIndex;
            end
        else
            finalFrequencyBinIndex = frequencyBinIndex;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%                              
        acqResults.channel(chIndex).carrFreq    = centerFreq - freqWindow ...
                                   + freqStep * (finalFrequencyBinIndex - 1);                         
        acqResults.channel(chIndex).bFound = true;

    else
        % No signal with this PRN 
        fprintf('.. ');

        acqResults.channel(chIndex).codePhase = NaN;
        acqResults.channel(chIndex).carrFreq  = NaN;
       acqResults.channel(chIndex).bFound = false;
    end
    
    acqResults.nrObs = chIndex;

    % Increment channel index
    chIndex = chIndex + 1;
end

% Print progress info
t = toc;
fprintf('|');
fprintf('\n*===');
for i = 1:(len-1)
    fprintf('===');
end
fprintf('*\n');
noOfAcquiredSatellites = length(find([acqResults.channel.bFound]==1));

fprintf('%d',noOfAcquiredSatellites);
fprintf(' %s',char(signalSettings.signal));
fprintf(' signals acquired in %6.2f sec.\n',t);

% Set duration of acquisition
acqResults.duration = t;

