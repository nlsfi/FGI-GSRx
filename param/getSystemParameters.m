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
function settings = getSystemParameters(settings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions sets any fixed GNSS parameters and constants 
% in the settings structure
%
%  Inputs: 
%       settings - Receiver settings 
%
%  Outputs:
%       settings - Updated receiver settings
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Meta data file reading
if settings.sys.loadIONMetaDataReading==1
    metaData = xmlParserIONMetaData(settings.sys.metaDataFileIn); 
    for i=1:length(settings.sys.enabledSignals)
        signal = settings.sys.enabledSignals{i};
        for j=1:length(metaData.enabledSignals)
            if strcmp(metaData.enabledSignals{j},signal)==1
                metaEnabledSignal = metaData.enabledSignals{j};
                settings.(signal).centerFrequency = metaData.(metaEnabledSignal).centerFrequency;
                settings.(signal).translatedFrequency = metaData.(metaEnabledSignal).translatedFrequency;
                settings.(signal).samplingFreq = metaData.freqBase*metaData.(metaEnabledSignal).rateFactor;
                settings.(signal).bandWidth = metaData.(metaEnabledSignal).bandwidth;
                if strcmp(metaData.(metaEnabledSignal).formatRawData,'IQ')==1
                    settings.(signal).complexData = true;
                    settings.(signal).iqSwap = false;
                    settings.(signal).sampleSize = metaData.sampleSizeInBytes*8*2; % Sample size for I+Q in bits
                elseif strcmp(metaData.(metaEnabledSignal).formatRawData,'QI')==1
                    settings.(signal).complexData = true;
                    settings.(signal).iqSwap = true;
                    settings.(signal).sampleSize = metaData.sampleSizeInBytes*8*2; % Sample size for I+Q in bits
                elseif strcmp(metaData.(metaEnabledSignal).formatRawData,'IF')==1
                    settings.(signal).complexData = false;
                    settings.(signal).iqSwap = false;
                    settings.(signal).sampleSize = metaData.sampleSizeInBytes*8*1; % Sample size for real sample in bits
                else
                    ;
                end
            end
        end
    end    
end

% Hardcoded parameter for the various systems
settings.gpsl1.codeLengthInChips = 1023; 
settings.gpsl1.codeFreqBasis = 1.023e6;
settings.gpsl1.carrierFreq = 1575.42e6;
settings.gpsl1.numberOfChannels = 12;
settings.gpsl1.preamble = [1 -1 -1 -1 1 -1 1 1];
settings.gpsl1.bitDuration = 20;   % Length of data bit [epochs]   
settings.gpsl1.secondaryCode = ones(1,20);   % Length of data bit [epochs]   
settings.gpsl1.preambleCorrThr = 153; 
settings.gpsl1.preambleIntervall = 6000; 
settings.gpsl1.frameLength = 30000; % 5 subframes x 300 bits x 20 ms/bit
settings.gpsl1.frequencyStep = 0;
settings.gpsl1.modulationFactor = 1;		 % Modulation factor. For GPS it is one.
settings.gpsl1.bitSyncConfidenceLevel = 6;

settings.gpsl1c.codeLengthInChips=10230;
settings.gpsl1c.codeFreqBasis=1.023e6;
settings.gpsl1c.carrierFreq=1575.42e6;
settings.gpsl1c.numberOfChannels=12;
settings.gpsl1c.bitDuration = 1;                % Length of data bit [epochs]
settings.gpsl1c.frequencyStep = 0;
settings.gpsl1c.preambleCorrThr = 1700;         % Overlay code length - 100
settings.gpsl1c.preambleIntervall = 1800;       % Data frame length
settings.gpsl1c.secondaryCode = 1;              % Overlay code is only utilized for frame synch so secondary code is set to 1
settings.gpsl1c.frameLength = 1800;             % (52 TOI bits + 1748 NAV message bits) * 10 ms/bit
if (strcmp(settings.gpsl1c.modType,'TMBOC'))
    settings.gpsl1c.modulationFactor = 12; 
else
    settings.gpsl1c.modulationFactor = 2;
end
settings.gpsl1c.bitSyncConfidenceLevel = 6;

settings.gale1b.codeLengthInChips=4092;
settings.gale1b.codeFreqBasis=1.023e6;
settings.gale1b.carrierFreq=1575.42e6;
settings.gale1b.numberOfChannels=12;
settings.gale1b.preamble = [-1 1 -1 1 1 -1 -1 -1 -1 -1];
settings.gale1b.bitDuration = 1;   % Length of data bit [epochs]   
settings.gale1b.secondaryCode = 1;   % Length of data bit [epochs]   
settings.gale1b.preambleCorrThr = 9.99; 
settings.gale1b.preambleIntervall = 250; 
settings.gale1b.frameLength = 10000; 
settings.gale1b.frequencyStep = 0;

if (strcmp(settings.gale1b.modType,'CBOC')==1)
    settings.gale1b.modulationFactor = 12; 
else
    settings.gale1b.modulationFactor = 2; %In case of BOC(1,1), modulationFactor should be 2.
end
settings.gale1b.bitSyncConfidenceLevel = 6;

settings.gale1c.codeLengthInChips=4092;
settings.gale1c.codeFreqBasis=1.023e6;
settings.gale1c.carrierFreq=1575.42e6;
settings.gale1c.numberOfChannels=12;
settings.gale1c.preamble = [-1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 -1 1 1 -1 1 1 -1 -1 1 -1];
settings.gale1c.preambleIntervall = 100; 
settings.gale1c.bitDuration = 0; 
settings.gale1c.secondaryCode = [-1 -1 1 1 1 -1 -1 -1 -1 -1 -1 -1 1 -1 1 -1 1 1 -1 1 1 -1 -1 1 -1];
settings.gale1c.preambleCorrThr = 9.99;
settings.gale1c.frequencyStep = 0;
if (strcmp(settings.gale1c.modType,'CBOC')==1)
    settings.gale1c.modulationFactor = 12; 
else
    settings.gale1c.modulationFactor = 2; %In case of BOC(1,1), modulationFactor should be 2.
end
settings.gale1c.bitSyncConfidenceLevel = 6;

settings.beib1.codeLengthInChips=2046;
settings.beib1.codeFreqBasis=2.046e6;
settings.beib1.carrierFreq=1561.098e6;
settings.beib1.numberOfChannels=12;
settings.beib1.bitDuration = 20;
settings.beib1.preambleCorrThr = 200; 
settings.beib1.preambleIntervall = 6000; 
settings.beib1.frameLength = 30000; 
settings.beib1.frequencyStep = 0;
settings.beib1.bitDurationGEO = 2;   % Length of data bit for GEO satellites[epochs]   
settings.beib1.bitDurationMEOIGSO = 20;   % Length of data bit for MEO/IGSO satellites[epochs]   
settings.beib1.secondaryCode = [-1 -1 -1 -1 -1 1 -1 -1 1 1 -1 1 -1 1 -1 -1 1 1 1 -1]; 
settings.beib1.preamble = [1 1 1 -1 -1 -1 1 -1 -1 1 -1];
settings.beib1.modulationFactor = 1;		 % Modulation factor. 
settings.beib1.bitSyncConfidenceLevel = 6;

settings.glol1.codeLengthInChips=511;
settings.glol1.codeFreqBasis=0.511e6;
settings.glol1.carrierFreq=1602e6;
settings.glol1.numberOfChannels=12;
settings.glol1.bitDuration = 20;    % Length of data bit [epochs]
settings.glol1.meanderBitDuration = 10;    % Length of meander data bit [epochs]
settings.glol1.frequencyStep = 0.5625e6;
settings.glol1.secondaryCode = ones(1,10);   % Length of data bit [epochs] 
settings.glol1.modulationFactor = 1;		 % Modulation factor. 
settings.glol1.preamble = [1 1 1 1 1 -1 -1 -1 1 1 -1 1 1 1 -1 1 -1 1 -1 -1 -1 -1 1 -1 -1 1 -1 1 1 -1];
settings.glol1.bitSyncConfidenceLevel = 12;
settings.glol1.preambleCorrThr = 290;
settings.glol1.preambleIntervall = 2000;
settings.glol1.frameLength = 30000; % 5 subframes x 300 bits x 20 ms/bit

%NAVIC (IRNSS) L5 settings
settings.navicl5.codeLengthInChips = 1023; 
settings.navicl5.codeFreqBasis = 1.023e6;
settings.navicl5.carrierFreq = 1176.45e6;
settings.navicl5.numberOfChannels = 12;
settings.navicl5.preamble = [1 1 1 -1 1 -1 1 1 1 -1 -1 1 -1 -1 -1 -1];
settings.navicl5.bitDuration = 20;   % Length of data bit [epochs]   
settings.navicl5.secondaryCode = ones(1,20);   % Length of data bit [epochs]   
settings.navicl5.preambleCorrThr = 306; 
settings.navicl5.preambleIntervall = 12000; 
settings.navicl5.frameLength = 12000*4; % 4 subframes 
settings.navicl5.frequencyStep = 0;
settings.navicl5.modulationFactor = 1;		 % Modulation factor. For GPS it is one.
settings.navicl5.bitSyncConfidenceLevel = 6;

% Physical constants
settings.const.PI = 3.1415926535898;
settings.const.SPEED_OF_LIGHT = 2.99792458e8;

settings.const.SECONDS_IN_MINUTE = 60; 
settings.const.SECONDS_IN_HOUR = 3600; 
settings.const.SECONDS_IN_DAY = 86400; 
settings.const.SECONDS_IN_HALF_WEEK = 302400;
settings.const.SECONDS_IN_WEEK = 604800;
settings.const.EARTH_SEMIMAJORAXIS = 6378137; 
settings.const.EARTH_FLATTENING = 1/298.257223563; 
settings.const.EARTH_GRAVCONSTANT = 3.986005e14; 
settings.const.EARTH_WGS84_ROT = 7.2921151467E-5; 
settings.const.C20 = -1082.62575e-6; % 2nd zonal harmonic of ellipsoid
settings.const.A_REF = 26559710;                        % CNAV2 Reference semi-major axis (meters)
settings.const.OMEGA_REFDOT = -2.6e-9*3.1415926535898;  % CNAV2 Reference rate of right ascension

settings.sys.nrOfChannels = 0;

% Total number of signals enabled
settings.sys.nrOfSignals = length(settings.sys.enabledSignals);

% Let's loop over all enabled signals
for i = 1:settings.sys.nrOfSignals

    % Extract block of parameters for one signal from settings
    signal = settings.sys.enabledSignals{i};
    paramBlock = settings.(signal);
    
    % Set additional block parameters
    paramBlock.samplesPerChip     = paramBlock.samplingFreq/paramBlock.codeFreqBasis; % Samples per chip     
    paramBlock.samplesPerCode = round(paramBlock.samplingFreq / (paramBlock.codeFreqBasis / paramBlock.codeLengthInChips)); % Samples per each code epoch
    paramBlock.bytesPerSample = (paramBlock.sampleSize)/8;

    paramBlock.codeLengthMs = 1000 * paramBlock.codeLengthInChips / paramBlock.codeFreqBasis;

    if settings.sys.loadIONMetaDataReading==1
       paramBlock.intermediateFreq = paramBlock.translatedFrequency; 
    else
       paramBlock.intermediateFreq = paramBlock.carrierFreq - paramBlock.centerFrequency;
    end
    paramBlock.signal = signal;   
    
    % If user requests us to read 0 ms it means we need to read the whole file
    if(settings.sys.msToProcess == 0)
        f=dir(paramBlock.rfFileName);
        f.bytes;
        samplesPerMs = paramBlock.samplingFreq/1000; % Number of samples per millisecond
        % Let's calculate how much data to skip and to read from the file
        msInFile = f.bytes/(paramBlock.bytesPerSample*samplesPerMs);
        maxMsToRead = msInFile - settings.sys.msToSkip;
        settings.sys.msToProcess = floor(maxMsToRead);
    end
    paramBlock.numberOfBytesToSkip = paramBlock.bytesPerSample*paramBlock.samplingFreq/1000*settings.sys.msToSkip;
    paramBlock.numberOfBytesToRead = paramBlock.bytesPerSample*paramBlock.samplingFreq/1000*settings.sys.msToProcess;
   
    if(paramBlock.complexData == true)
        paramBlock.dataType = strcat('int',num2str(paramBlock.sampleSize/2));
    else
        paramBlock.dataType = strcat('int',num2str(paramBlock.sampleSize));
    end
  
    % Add number of channels for one signal to total number of channels
    settings.sys.nrOfChannels = settings.sys.nrOfChannels + paramBlock.numberOfChannels;
        
    % Copy block of parameters back to settings
    settings.(signal) = paramBlock;

    disp(strcat(signal,' Enabled'));
end

