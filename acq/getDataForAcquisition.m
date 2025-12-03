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
function [rfData,sampleCnt] = getDataForAcquisition(params,msToProcess)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function reads RF data from a file
%
%  Inputs: 
%       params - Configuration parameters for one signal
%       msToSkip - ms to skip from beginning of file
%       msToProcess - ms to read from file
%
%   Output:
%       rfData - data array with RfData
%       sampleCnt - sample count at the start of the reading
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Temporary variables
fileNameStr = params.rfFileName; % Filename for RF data file
bytesPerSample = params.bytesPerSample; % Number of bytes for each sample
samplesPerMs = params.samplingFreq/1000; % Number of samples per millisecond
bytesToSkip = params.numberOfBytesToSkip; % samplesToSkip * bytesPerSample;
samplesToRead = msToProcess*samplesPerMs; % Total number of samples to read    


% Lets open the file and read the data
[fid, message] = fopen(fileNameStr, 'rb');

if (fid > 0)
    sampleCnt =(ftell(fid))/(bytesPerSample);        
    rfData = readRfData(fid, params.dataType, params.complexData, params.iqSwap, bytesToSkip, samplesToRead);       
    fclose(fid);
else
    fprintf( 'Unable to open RF data file ''%s''\n', fileNameStr );
    return;        
end
