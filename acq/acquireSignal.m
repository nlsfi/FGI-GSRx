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
	elseif strcmp(signalSettings.signal,'gpsl1c')==1
        % Generate ranging code
        PrnCodeL1CP = gpsl1cPGeneratePrnCode(PRN);
        % Add code modulation
        modulatedCodeL1CP = gpsl1cPModulatePrnCode(PrnCodeL1CP, signalSettings);
        % Upsample code to sampling frequency
        upSampledCodeL1CP = upSampleCode(modulatedCodeL1CP, signalSettings);
        % Perform the parallel code phase search
        results = searchFreqCodePhase(upSampledCodeL1CP, signalSettings, pRfData, PRN);		
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
        acqResults.channel(chIndex).codePhase = codePhase;        
                   
        acqResults.channel(chIndex).doppler    =  - freqWindow ...
                + freqStep * (frequencyBinIndex - 1);
        acqResults.channel(chIndex).carrFreq    = centerFreq - freqWindow ...
                                   + freqStep * (frequencyBinIndex - 1);
        acqResults.channel(chIndex).bFound = true;

        %Estimate fine doppler     
        %%Fine Doppler estimation is carried out with a second stage acquisition around +/-X Hz 
        %%of estimated Doppler at the first acquisition stage. In order to get the full signal energy 
        %%(i.e, in order to avoid mid-bit transition withing 4 ms chunk), the incoming signal is  
        %%advanced to the value estimated by the codePhase in samples at the first acquisition stage. 
        %%This is working fine, and we will see how it performs with many other data sets. 

        %Change the frequency search range, frequency bin size and coherent and non-coherent integration number for fine frequency search            
        %Save first the old user-defined values for restoring those later            
        cohIntNumber = signalSettings.cohIntNumber;        
        nonCohIntNumber = signalSettings.nonCohIntNumber;         
        freqWindow = signalSettings.maxSearchFreq; % One sided        
        intermediateFreq = signalSettings.intermediateFreq;        
        codeLengthMs = signalSettings.codeLengthMs;                                                                             
        signalSettings.maxSearchFreq=1000; % One sided        
        signalSettings.intermediateFreq = signalSettings.intermediateFreq + acqResults.channel(chIndex).doppler;        
             
        if (strcmp(signalSettings.signal(1:5),'gale1')==1)    
            signalSettings.cohIntNumber = 1;                     
            signalSettings.nonCohIntNumber = 1;     
            signalSettings.codeLengthMs =20; %use 20 in order to have better resolution  
            % Number of the frequency bins for the given acquisition band        
            freqStepFineEstimation = 1000/(2*signalSettings.codeLengthMs*signalSettings.cohIntNumber);        
            % Number of the frequency bins for the given acquisition band (500Hz steps)        
            numberOfFrqBinsFineEstimation = floor(2 * signalSettings.maxSearchFreq/freqStepFineEstimation + 1);
            frqBins = signalSettings.intermediateFreq + (PRN-8)*signalSettings.frequencyStep - ...
                               signalSettings.maxSearchFreq + ...
                               freqStepFineEstimation * [1:1:numberOfFrqBinsFineEstimation];   
            dataResultsFine = searchFreqCodePhase(upSampledCodeE1B, signalSettings, pRfData(codePhase-1:end), PRN);
            pilotResultsFine = searchFreqCodePhase(upSampledCodeE1C, signalSettings, pRfData(codePhase-1:end), PRN);
            [peakSizeData, frequencyBinIndexData] = max(max(dataResultsFine, [], 2));
            [peakSizePilot, frequencyBinIndexPilot] = max(max(pilotResultsFine, [], 2));
            searchResults = dataResultsFine + abs(pilotResultsFine);     
        elseif strcmp(signalSettings.signal,'gpsl1c')==1
            signalSettings.cohIntNumber = 1;
            signalSettings.nonCohIntNumber = 1;
            signalSettings.codeLengthMs = 40;
            % Number of the frequency bins for the given acquisition band
            freqStepFineEstimation = 1000/(2*signalSettings.codeLengthMs*signalSettings.cohIntNumber);
            % Number of the frequency bins for the given acquisition band
            numberOfFrqBinsFineEstimation = floor(2 * signalSettings.maxSearchFreq/freqStepFineEstimation + 1);
            frqBins = signalSettings.intermediateFreq + (PRN-8)*signalSettings.frequencyStep - ...
                signalSettings.maxSearchFreq + ...
                freqStepFineEstimation * [1:1:numberOfFrqBinsFineEstimation];
            searchResults = searchFreqCodePhase(upSampledCodeL1CP, signalSettings, pRfData(codePhase-1:end), PRN);            
        else
            if  (strcmp(signalSettings.signal(1:5),'beib1')==1)
                %In case of GEO satellites, use higher non-coherent
                %integration due to faster bit rate (500 bps)
                if PRN<5
                    signalSettings.cohIntNumber = 2 ;                     
                    signalSettings.nonCohIntNumber = 5;                    
                else
                    signalSettings.cohIntNumber = 1 ;                     
                    signalSettings.nonCohIntNumber = 3;                   
                end
            else
                signalSettings.cohIntNumber = 2 ;                     
                signalSettings.nonCohIntNumber = 5;   
            end
            signalSettings.codeLengthMs = 20;
            % Number of the frequency bins for the given acquisition band        
            freqStepFineEstimation = 1000/(2*signalSettings.codeLengthMs*signalSettings.cohIntNumber);        
            % Number of the frequency bins for the given acquisition band (500Hz steps)        
            numberOfFrqBinsFineEstimation = floor(2 * signalSettings.maxSearchFreq/freqStepFineEstimation + 1);
            frqBins = signalSettings.intermediateFreq + (PRN-8)*signalSettings.frequencyStep - ...
                               signalSettings.maxSearchFreq + ...
                               freqStepFineEstimation * [1:1:numberOfFrqBinsFineEstimation];   
            searchResults = searchFreqCodePhase(upSampledCode, signalSettings, pRfData(codePhase:end), PRN);        
        end
            %Find the code phase peak: should be around the first sample        
            [peakVal codePhase] = max(max(searchResults(:,:)));        
            [fineDopplerIndexVal fineDopplerIndex] = max(searchResults(:,codePhase));                   
            fineDoppler = frqBins(fineDopplerIndex) - signalSettings.intermediateFreq - (PRN-8)*signalSettings.frequencyStep;                 
            %Restore original acquisition parameters                    
            signalSettings.cohIntNumber=cohIntNumber;        
            signalSettings.nonCohIntNumber = nonCohIntNumber;         
            signalSettings.maxSearchFreq = freqWindow; % One sided        
            signalSettings.intermediateFreq = intermediateFreq;
            signalSettings.codeLengthMs = codeLengthMs;        
            %fineDoppler = searchFreqCodePhaseFineEstimation(upSampledCode(1,:), signalSettings, pRfData(codePhase:end), PRN, acqResults.channel(chIndex).doppler);
            acqResults.channel(chIndex).doppler    = acqResults.channel(chIndex).doppler + fineDoppler;
            acqResults.channel(chIndex).carrFreq    = signalSettings.intermediateFreq + (PRN-8)*signalSettings.frequencyStep + acqResults.channel(chIndex).doppler;                
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

