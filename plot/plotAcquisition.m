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
function plotAcquisition(acqResults,allSettings, prefix)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function plots bar plot of acquisition result. Bars are shown for those satellites which are not 
% present in the acquisition list
%
% Inputs:
%   acqResults    - Acquisition results from function acquisition.
%   allSettings   - Receiver settings
%   prefix        - Prefix for title of plot
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if user has enabled functionality
if(allSettings.sys.plotAcquisition == false)
    return;
end

% Number of found satellites for plots
nrFound = sum([acqResults.channel.bFound]);

s = ceil(sqrt(nrFound));
t = ceil(nrFound/s);

% Plot spectrum plots in one figure
figure('Position',[200,50,1000,600])
ind = 1;
for i=1:acqResults.nrObs
    if(acqResults.channel(i).bFound == true)    
        PRN = acqResults.channel(i).SvId.satId;
        subplot(s,t,ind);
        plot(acqResults.channel(i).spec);
        title('');
        xlabel('Code Phase (samples)');
        ylabel('Amplitude (a.u.)');
        title([prefix, ' PRN ',int2str(PRN)]);
        grid on;    
        drawnow;
        ind = ind + 1;
    end
end

% Temporary variables for plotting
peakMetric = [acqResults.channel.peakMetric];
bFound = [acqResults.channel.bFound];
prn = [acqResults.channel.SvId];
index = [prn.satId];
acquiredPRNs = peakMetric .* bFound;

% Plot bars of all satellites present in the acquisition list
figure();
axesHandler = newplot();
bar(axesHandler, index,peakMetric);

title (axesHandler, strcat(prefix, ' Acquisition Result'));
xlabel(axesHandler, 'PRN number (no bar - SV is not in the acquisition list)');
ylabel(axesHandler, 'Acquisition Metric');

pastAxis = axis(axesHandler);
axis  (axesHandler, [0, 37, 0, pastAxis(4)]);
set   (axesHandler, 'XMinorTick', 'on');
set   (axesHandler, 'YGrid', 'on');

% Mark acquired signals 
hold(axesHandler, 'on');
bar (axesHandler, index, acquiredPRNs, 'FaceColor', [0 0.9 0]);
hold(axesHandler, 'off');
legend(axesHandler, 'Not acquired signals', 'Acquired signals');
drawnow;
