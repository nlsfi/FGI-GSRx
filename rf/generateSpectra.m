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
function generateSpectra(allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function reads the RF data and plots the time domain and 
% frequency domain plots of the data and the histogram for the data bits. 
%
%  Inputs: 
%       allSettings - Receiver settings 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if user has enabled functionality
if(allSettings.sys.plotSpectra == false)
    return;
end

% Let's loop over all enabled signals
for i = 1:allSettings.sys.nrOfSignals

    % Set up new figure
    figure('Position',[400,100,1000,600])

    % Extract block of parameters for one signal from settings
    signal = allSettings.sys.enabledSignals{i};
    paramBlock=allSettings.(signal);
    
    samplesPerMs = paramBlock.samplingFreq/1000; % Number of samples per millisecond    
    samplesToRead = 10 * samplesPerMs; % Let's use 10 ms for the plot    
    
    % Read RF Data
    fileNameStr = paramBlock.rfFileName; % Filename for RF data file
    
    % Lets open the file and read the data
    [fid, message] = fopen(fileNameStr, 'rb');

    if (fid > 0)
        pRfData = readRfData(fid, paramBlock.dataType, paramBlock.complexData, paramBlock.iqSwap, paramBlock.numberOfBytesToSkip, samplesToRead);    
        fclose(fid);
    else
        fprintf( 'Unable to open RF data file ''%s''\n', fileNameStr );
        return;        
    end
    
    % Plot data
    plotTimeDomain(paramBlock,pRfData);
    plotFrequencyDomain(paramBlock,pRfData);
    plotHistogram(paramBlock,pRfData);
    drawnow;

end



