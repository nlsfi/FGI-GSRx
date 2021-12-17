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
function [obs, sat, nav] = doNavigation(obsData, allSettings, ephData)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the main loop for navigation. It utlizes receiver observables, satellite
% specific information, correction information, and offers a navigation
% solution based on the user configuration settings
%
% Inputs:
%   obsData         - structure with observations for all measurement epochs
%   allSettings     - configuration parameters
%   ephData         - ephemeris data for all systems
%
% Outputs:
%   obsData         - strcture with observations for all measurement epochs
%   satData         - structure with satellite info for all epochs
%   navData         - Navigation solution for all epochs
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialise navigation
[obsData, nrOfEpochs, startSampleCount, navData, samplesPerMs] = initNavigation(obsData, allSettings);

% Flag for initial round
bInit = true; 

%Initialize satData structure for future use
satData = [];


%Idea here is to generate correction data that can be applied to different models 
%depending on the correction type (for ionosphere, it can be broadcast iono data to be applied to generate ionosphere correction data)         
[corrInputData] = generateCorrectionInputData(obsData,ephData, allSettings);


% Index for nav solution
fixIndex = 1;

% Loop over all epochs
for currMeasNr = 1:nrOfEpochs
    
    % Extract sample count for current epoch
    sampleCount = startSampleCount + samplesPerMs*allSettings.nav.navSolPeriod*(currMeasNr-1);
    
    % Extract transmit time for each signal at given sample count
    [obsData] = getTransmitTime(obsData,sampleCount, allSettings);
    
    % For the first lap we will set the receiver time to a fixed offset
    % from one selected transmission TOW.
    if(bInit)
        obsData = getTowPerConstellation(obsData, allSettings);

        % TBA Init carrier smoother
        % smoother = initCarrierSmoother(settings);
        bInit = false;
    else
         % Update estimated tow for next measurement based on update rate
         % and initial estimate
         obsData = updateReceiverTimeEstimate(obsData, allSettings);        
    end

     % Calcualte pseudoranges from transmission times and receiver time 
     obsData = calculatePseudoRanges(obsData, allSettings);
    
     % Here we get all the info on the satellites
     [obsData, satData] = getSatelliteInfo(obsData, ephData, navData, allSettings);     
     
     % Here we apply all known corrections to the observations (not SSR
     % corrections)
     obsData = applyObservationCorrections(allSettings, obsData, satData, navData, corrInputData);   
       
     % Finally we do some checks to decide what observations to use (elev, azim, RAIM etc)
     obsData = checkObservations(obsData,satData,allSettings,navData);

     % Now finally we calculate the actual navigation solution
     [obsData, satData, navData] = getNavSolution(obsData, satData, navData, allSettings);
     
    % Then we update the state of the navigation
     navData = updateNavState(navData);

     % Update output to UI 
     showNavStatus(allSettings, currMeasNr, navData, obsData, satData);
     
     % Copy to new structure that holds data for all measuremenet epochs
     obs{fixIndex} = obsData;
     sat{fixIndex} = satData;
     nav{fixIndex} = navData;

     fixIndex = fixIndex + 1;
     
end



