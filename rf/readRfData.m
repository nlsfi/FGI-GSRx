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
function rfData = readRfData(fid, dataType, complexData, iqSwap, bytesToSkip, samplesToRead)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function reads RF data from a file starting from a given offset
%
% Inputs: 
%   fid                 - RF file identifier
%   dataType            - Type of data to read
%   complexData         - Complex or Real data
%   bytesToSkip         - Bytes to skip from beginning of file
%   samplesToRead       - Samples to read from file
%
% Output:
%    rfData             - data array with RfData
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Move the starting point of processing. 
fseek(fid, bytesToSkip, 'bof');

% For complex data
if (complexData == true)
    [data, samplesRead] = fread(fid, [1,2*samplesToRead], dataType);

    % If did not read in enough samples, then could be out of 
    % data - better exit 
    if (samplesRead ~= 2*samplesToRead)
        disp('Not able to read the specified number of samples from file, exiting!')
        return
    end   
    
    Idata = data(1:2:end);
    Qdata = data(2:2:end);
    if iqSwap == true
        Cdata = Qdata + i.* Idata;
    else
        Cdata = Idata + i.* Qdata;
    end
    rfData=Cdata;        
else
    [data, samplesRead] = fread(fid, [1,samplesToRead], dataType);
    
    % If did not read in enough samples, then could be out of 
    % data - better exit 
    if (samplesRead ~= samplesToRead)
        disp('Not able to read the specified number of samples from file, exiting!')
        return
    end    
    
    rfData=data;
end


