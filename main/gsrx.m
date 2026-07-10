%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2015-2026 Finnish Geospatial Research Institute FGI, National
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
function [] = gsrx(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Main function for the FGI-GSRx matlab software receiver
%
% Input (optional):
%   vararging   -   Name of user parameter file
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Setting some display font settings.
set(0,'defaultaxesfontsize',10);
set(0,'defaultlinelinewidth',2);

% Clean up the environment
close all; 
clc;
clearvars -except varargin

% Set number format
format ('compact');
format ('long', 'g');

% Print startup text 
fprintf(['\n',...
    'Welcome to:  FGI-GSRx software GNSS receiver\n', ...
    'by the Finnish Geospatial Research Institute\n\n']);
fprintf('                   -------------------------------\n\n');

if isempty(varargin)
    % Initialize receiver settings (parameters)
    settings = readSettings(varargin);
else
    settings = readSettings(varargin{1});
end
% Read existing pre processed data file
if(settings.sys.loadDataFile == true)
    newSettings = settings; % Copy parameters to temporary variable
    load(settings.sys.dataFileIn);
    settings = newSettings; % Overwrite parameters in data file
end

% Generate spectrum plots
if settings.sys.plotSpectra == 1
    generateSpectra(settings);
end

% Define ephData if not available
if(~exist('ephData'))
    ephData = [];
end

% Execute acquisition if results not allready available
if(~exist('acqData'))
    acqData = doAcquisition(settings);         
end

% Plot acquisition results
if settings.sys.plotAcquisition == 1
   % Loop over all signals
    for i = 1:settings.sys.nrOfSignals   
        signal = settings.sys.enabledSignals{i};             
        plotAcquisition(acqData.(signal),settings, char(signal)); 
    end         
end
% Save available results so far to file
if(settings.sys.saveDataFile == true)
    save(settings.sys.dataFileOut,'settings','acqData','ephData');
end

if(~exist('trackData'))
    tic;
    if (contains(settings.sys.enabledSignals,'gpsl1') == 1)
        if (~exist('trackResults'))
            if strcmp(settings.gpsl1.trackingMode,'20msTracking') == 1
                %Find out the bit boundaries for GPS L1 signal: continue tracking the
                %signal for 2 seconds to detect bit boundaries
                [acqData, settings] = doBitSynchronization(acqData,settings);                                         
            end
        end
    end


    if (settings.sys.parallelChannelTracking)
        if (~exist('trackResults'))
            trackDataFileName = initializeAndSplitTrackingPerChannel(acqData, settings); 
            if settings.sys.PCTenabled == 1
                trackData = doTrackingPCT(trackDataFileName,settings);   
            else
                doTrackingParallel(trackDataFileName,settings); 
                return;
            end            
        else             
            trackData = combineSingleTrackChannelData(settings);
        end
    else    
        trackData = doTracking(acqData, settings);       
    end
    trackData.trackingRunTime = toc;
else
    if (contains(settings.sys.enabledSignals,'gpsl1') == 1)
        if strcmp(settings.gpsl1.trackingMode,'20msTracking') == 1
            % Update tracking parameters for 20 ms integration for 
            settings = gpsl1UpdateTrackingParametersFor20msIntegration(settings);
        end
    end
end


% Save results so far to file
if(settings.sys.saveDataFile == true)
    save(settings.sys.dataFileOut,'settings','acqData','ephData','trackData');
end


% Plot tracking results
if settings.sys.plotTracking == 1                
    plotTracking(trackData, settings);    
end


% Convert track data to useful observations for navigation if data not already available
if(~exist('obsData'))
    obsData = generateObservations(trackData, settings);
end

% Save results so far to file
if(settings.sys.saveDataFile == true)
    save(settings.sys.dataFileOut,'settings','acqData','ephData','trackData','obsData');
end

% Execute frame decoding. Needed for time stamps at least 
[obsData, ephData] = doFrameDecoding(obsData, trackData, settings);

% Save results so far to file
if(settings.sys.saveDataFile == true)
    save(settings.sys.dataFileOut,'settings','acqData','ephData','trackData','obsData');
end

% Execute navigation
[obsData,satData,navData] = doNavigation(obsData, settings, ephData);

% Calculate and output statistics
% True values
trueLat=settings.nav.trueLat; 
trueLong=settings.nav.trueLong;
trueHeight=settings.nav.trueHeight;

% Calculate statistics
statResults = calcStatistics(navData,[trueLat trueLong trueHeight],settings.nav.navSolPeriod,settings.const);  

% Output statistics
statResults.hor
statResults.ver
statResults.dop
statResults.RMS3D


% Generate rinex file(s)
if isfield(settings, 'rinex') % backwards compatibility for older param files
    if settings.rinex.enableRINEX == true
        generateRinex(settings, obsData, navData, ephData);
    end
end