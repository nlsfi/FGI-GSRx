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
function plotHistogram(signalSettings, rfData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function plot the histogram of the RF data
%
% Inputs: 
%   signalSettings     - Receiver settings
%   rfData          - RF data 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For titles to figure
prefix = signalSettings.signal;

if (signalSettings.complexData == false)
    % Real data
    %figure
    subplot(3,1,3);
    hist(rfData, -128:128) 

    dmax = max(abs(rfData)) + 1;
    axis tight;     adata = axis;
    axis([-dmax dmax adata(3) adata(4)]);
    grid on;        
    title (strcat(prefix,' histogram'));
    xlabel('Bin');  ylabel('Number in bin');
else
    % Complex data
    %figure    
    subplot(3,2,5);    
    hist(real(rfData), -128:128)
    dmax = max(abs(rfData)) + 1;
    axis tight;     adata = axis;
    axis([-dmax dmax adata(3) adata(4)]);
    grid on;        
    title (strcat(prefix,' histogram (I)'));
    xlabel('Bin');  ylabel('Number in bin');

    %figure    
    subplot(3,2,6);
    hist(imag(rfData), -128:128)
    dmax = max(abs(rfData)) + 1;
    axis tight;     adata = axis;
    axis([-dmax dmax adata(3) adata(4)]);
    grid on;        
    title (strcat(prefix,' histogram (Q)'));
    xlabel('Bin');  ylabel('Number in bin');

end

