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
function plotTimeDomain(signalSettings, rfData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function plot the RF data in time domain
%
% Inputs: 
%   signalSettings      - Signal specific receiver settings
%   rfData              - RF data to be plotted
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set some basic temporary variables
samplesPerCode = signalSettings.samplesPerCode;
timeScale = 0 : 1/signalSettings.samplingFreq : 5e-3;
prefix = signalSettings.signal;

if (signalSettings.complexData==false)
    % Real data
    subplot(3,1,1);
    plot(1000 * timeScale(1:round(samplesPerCode/50)), ...
        rfData(1:round(samplesPerCode/50)));

    axis tight;    grid on;
    title (strcat(prefix,' time domain plot'));
    xlabel('Time (ms)'); ylabel('Amplitude');
else
    % Complex data
    subplot(3,2,1);
    plot(1000 * timeScale(1:round(samplesPerCode/50)), ...
        real(rfData(1:round(samplesPerCode/50))));

    axis tight;    grid on;
    title (strcat(prefix,' time domain plot (I)'));
    xlabel('Time (ms)'); ylabel('Amplitude');

    subplot(3,2,2);
    plot(1000 * timeScale(1:round(samplesPerCode/50)), ...
        imag(rfData(1:round(samplesPerCode/50))));

    axis tight;    grid on;
    title (strcat(prefix,' time domain plot (Q)'));
    xlabel('Time (ms)'); ylabel('Amplitude');

end


