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
function plotTracking(tR, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function plots the tracking results.
%
% Inputs:
%   tR              - Results from signal tracking for one signals
%   allSettings     - Receiver settings
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check if user has enabled functionality
if(allSettings.sys.plotTracking == false)
    return;
end

displayPattern=['b-d'; 'r-o'; 'g-x' ; 'm-s' ; 'y-+'; 'k->'; 'c-<'; 'b--';'g--';'r--';'m--'; 'c--';'y--';'k--';];

% Loop over all signals
for signalNr = 1:allSettings.sys.nrOfSignals
    
    % Extract signal acronym
    signal = allSettings.sys.enabledSignals{signalNr};

    % Loop over all channels
    for channelNr=1:tR.(signal).nrObs
        tC = tR.(signal).channel(channelNr);
        sampleSpacing = tC.PDIcarr*1000;
        timeAxisInMs = sampleSpacing:sampleSpacing:length(tC.I_P); % create the time vector for the x-axis        
        % The number 200 is added just for more convenient handling of the open
        % figure windows, when many figures are closed and reopened.
        % Figures drawn or opened by the user, will not be "overwritten" by
        % this function.

        figure(channelNr +signalNr*100);
        clf(channelNr +signalNr*100);
        set(channelNr +signalNr*100, 'Name', ['Channel ', num2str(channelNr), ...
                                     ' (PRN ', num2str(tC.SvId.satId), ' ', signal, ...
                                     ') results']);

%% Draw axes ==============================================================
        % Row 1
        figureHandle(1, 1) = subplot(3, 3, 1);
        figureHandle(1, 2) = subplot(3, 3, [2 3]);
        % Row 2
        figureHandle(2, 1) = subplot(3, 3, 4);
        figureHandle(2, 2) = subplot(3, 3, [5 6]);
        % Row 3
        figureHandle(3, 1) = subplot(3, 3, 7);
        figureHandle(3, 2) = subplot(3, 3, 8);
        figureHandle(3, 3) = subplot(3, 3, 9);

%% Plot all figures =======================================================
        %----- Discrete-Time Scatter Plot ---------------------------------
        plot(figureHandle(1, 1), tC.I_P(timeAxisInMs),...
                            tC.Q_P(timeAxisInMs), ...
                            '.');

        grid  (figureHandle(1, 1));
        axis  (figureHandle(1, 1), 'equal');
        title (figureHandle(1, 1), 'Discrete-Time Scatter Plot');
        xlabel(figureHandle(1, 1), 'I prompt');
        ylabel(figureHandle(1, 1), 'Q prompt');

        %----- Navigation bits ---------------------------------------------------
        plot  (figureHandle(1, 2), timeAxisInMs/1000, ...
                              tC.I_P(timeAxisInMs), ...
                              timeAxisInMs/1000, ...
                              tC.Q_P(timeAxisInMs));

        grid  (figureHandle(1, 2));
        title (figureHandle(1, 2), 'In-phase (I_P) and Quad-phase (Q_P) component of the received signal');
        xlabel(figureHandle(1, 2), 'Time (s)');
        axis  (figureHandle(1, 2), 'tight');
        legendHandle = legend(figureHandle(1, 2), '${I_P}$','${Q_P}$');
        
        set(legendHandle, 'Interpreter', 'Latex');            
        
        %----- PLL discriminator unfiltered--------------------------------
        plot  (figureHandle(2, 1), timeAxisInMs/1000, ...
                              tC.doppler(timeAxisInMs), 'r');      

        grid  (figureHandle(2, 1));
        axis  (figureHandle(2, 1), 'tight');
        xlabel(figureHandle(2, 1), 'Time (s)');
        ylabel(figureHandle(2, 1), 'Doppler');
        title (figureHandle(2, 1), 'Estimated Doppler');

        %----- Early, Prompt and Late Correlation Output-------------------
        plot(figureHandle(2, 2), timeAxisInMs/1000, ...
                            [sqrt(tC.I_E(timeAxisInMs).^2 + ...
                                  tC.Q_E(timeAxisInMs).^2)', ...
                             sqrt(tC.I_P(timeAxisInMs).^2 + ...
                                  tC.Q_P(timeAxisInMs).^2)', ...
                             sqrt(tC.I_L(timeAxisInMs).^2 + ...
                                  tC.Q_L(timeAxisInMs).^2)'],'-*');

        grid  (figureHandle(2, 2));
        title (figureHandle(2, 2), 'Correlation results');
        xlabel(figureHandle(2, 2), 'Time (s)');
        axis  (figureHandle(2, 2), 'tight');
        
        legendHandle = legend(figureHandle(2, 2), '$\sqrt{I_{E}^2 + Q_{E}^2}$', ...
                                        '$\sqrt{I_{P}^2 + Q_{P}^2}$', ...
                                        '$\sqrt{I_{L}^2 + Q_{L}^2}$');
                                
        set(legendHandle, 'Interpreter', 'Latex');
        %----- PLL Lock Indicator------------------------------------------
        plot  (figureHandle(3, 1), timeAxisInMs/1000, tC.pllLockIndicator(timeAxisInMs), 'b');      

        grid  (figureHandle(3, 1));
        axis  (figureHandle(3, 1), 'tight');
        xlabel(figureHandle(3, 1), 'Time (s)');
        ylabel(figureHandle(3, 1), 'Amplitude');
        title (figureHandle(3, 1), 'PLL Lock Indicator');

        %----- Unfiltered DLL discriminator--------------------------------
        plot  (figureHandle(3, 2), timeAxisInMs/1000,tC.dllDiscr(timeAxisInMs), 'r');      

        grid  (figureHandle(3, 2));
        axis  (figureHandle(3, 2), 'tight');
        xlabel(figureHandle(3, 2), 'Time (s)');
        ylabel(figureHandle(3, 2), 'Amplitude');
        title (figureHandle(3, 2), 'Raw DLL discriminator');

        %----- FLL Lock Indicator------------------------------------------
        plot  (figureHandle(3, 3), timeAxisInMs/1000, ...
                              tC.fllLockIndicator(timeAxisInMs), 'b');      
        grid  (figureHandle(3, 3));
        axis  (figureHandle(3, 3), 'tight');
        xlabel(figureHandle(3, 3), 'Time (s)');
        ylabel(figureHandle(3, 3), 'Amplitude');
        title (figureHandle(3, 3), 'FLL Lock Indicator');
    end % for channelNr 
    
    figure; hold on; grid on;        
    visiblePRN=[];
    dispind = 1;
    for channelNr=1:tR.(signal).nrObs
        tC = tR.(signal).channel(channelNr);
        sampleSpacing = tC.PDIcarr*1000;
        timeAxisInMs = sampleSpacing:sampleSpacing:length(tC.I_P); % create the time vector for the x-axis
        plot(timeAxisInMs/1000,round(tC.meanCN0fromSNR(timeAxisInMs)),displayPattern(dispind,:)); hold on; grid on;  
        dispind=dispind+1;
        visiblePRN = [visiblePRN double(tC.SvId.satId)];         
        title(['Carrier-to-Noise density ratio (C/N_0) for the tracked ', signal, ' satellites']);
        xlabel('Time (s)');
        ylabel('C/N_0 (dB-Hz)');                
    end       
    legend(num2str(visiblePRN'));    
end %for signalNr







