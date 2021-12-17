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
function [tR, rawSignal] = getDataForCorrelation(fid,tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read data for processing
%
% Inputs:
%   fid             - RF file identifier
%   tR              - Results from signal tracking for one signals
%   ch              - Channel index
%
% Outputs:
%   tR              - Results from signal tracking for one signals
%   rawSignal       - Raw RF data 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set local variables
trackChannelData = tR.channel(ch);
loopCnt = trackChannelData.loopCnt;
dataCoeff = 1/tR.samplesPerRead;
complexData = tR.complexData;
iqSwap = tR.iqSwap;

if(trackChannelData.bInited)
    codeFreq      = trackChannelData.prevCodeFreq;  
    codePhase  = trackChannelData.prevCodePhase; % residual code phase from previous round    
    %fseek(fid, tR.sampleSize/8*trackChannelData.prevAbsoluteSample,'bof');   
    bytesToSkip = tR.sampleSize/8*trackChannelData.prevAbsoluteSample;
else
    codeFreq = tR.codeFreqBasis;    
    codePhase  = 0; % First epoch. No previous value exist    
    %fseek(fid, ...
    %    tR.numberOfBytesToSkip + (trackChannelData.acquiredCodePhase-1)*tR.sampleSize/8, ...
    %    'bof');         
    bytesToSkip =  tR.numberOfBytesToSkip + (trackChannelData.acquiredCodePhase-1)*tR.sampleSize/8;
end

% Calculate how much data to read and step size
trackChannelData.codePhaseStep(loopCnt) = codeFreq / tR.samplingFreq;
trackChannelData.blockSize(loopCnt) = ceil((tR.codeLengthInChips-codePhase) / trackChannelData.codePhaseStep(loopCnt));

% Copy the block size to read
blockSize = trackChannelData.blockSize(loopCnt);

rawSignal = readRfData(fid, tR.dataType, complexData,tR.iqSwap, bytesToSkip, blockSize);

% Copy updated local variables
tR.channel(ch) = trackChannelData;

