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
function plotFrequencyDomain(signalSettings, rfData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function plot the RF data in the frequency domain
%
% Inputs: 
%   signalSettings      - Signal specific receiver settings
%   rfData          - RF data to be plotted
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extract prefix for plot titles
prefix = signalSettings.signal;

% Generate figure
if (signalSettings.complexData==false) 
    % Real data
    subplot(3,1,2);
    [Pxx,f]=fftSpec(rfData, 32758, 0.0652, 16368, signalSettings.samplingFreq, 0);
    plot(f/1e6, Pxx);
else
    % Complex Data
    subplot(3,2,3);
    [Pxx,f]=fftSpec(rfData, 32758, 0.0652, 16368, signalSettings.samplingFreq, 1);
    plot(([-(f(length(f)/2:-1:1));f(1:length(f)/2)])/1e6, ...
        10*log10([Pxx(length(f)/2+1:end);
        Pxx(1:length(f)/2)]));
end  
axis tight;
grid on;
title (strcat(prefix,' frequency domain plot'));
xlabel('Frequency (MHz)'); ylabel('Magnitude');


