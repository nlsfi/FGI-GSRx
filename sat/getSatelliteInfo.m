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
function [obs, sat] = getSatelliteInfo(obs, ephData, navSolution, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates all the satellite positions and velocities for
% one epoch
%
% Inputs: 
%   obs             - Observations for one epoch
%   ephData         -  ephemeris data for all systems
%   navSolution     - Navigation information
%   allSettings     - Receiver configuration settings
%
% Outputs:
%   obs             - Observations for one epoch
%   sat             - satellite data for one epoch
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop over all signals
for signalNr = 1:allSettings.sys.nrOfSignals
        
    % Extract signal acronym
    signal = allSettings.sys.enabledSignals{signalNr};
    
    % Loop over all channels
    for channelNr = 1:obs.(signal).nrObs
        if(obs.(signal).channel(channelNr).bObsOk)
            
            % Set function to call
            codeFunc = str2func([signal,'Satpos']);
            
            % Temporary varaibel for satellite indexing
            prn = obs.(signal).channel(channelNr).SvId.satId;
            
            % Calculate satellite info for each system
            [Pos, Clock, T_GD, Vel, Health, Accuracy] = ...
                codeFunc(obs.(signal).channel(channelNr).transmitTime, prn, ephData.(signal),allSettings.const);  

            % Update sat data structure
            sat.(signal).channel(channelNr).SvId = obs.(signal).channel(channelNr).SvId;
            sat.(signal).channel(channelNr).refTime = obs.(signal).channel(channelNr).transmitTime; 
            sat.(signal).channel(channelNr).Pos = Pos;
            sat.(signal).channel(channelNr).Clock = Clock;
            sat.(signal).channel(channelNr).T_GD = T_GD;
            sat.(signal).channel(channelNr).Vel = Vel;
            sat.(signal).channel(channelNr).Health = Health;
            sat.(signal).channel(channelNr).Accuracy = Accuracy;
            
            % Temporary variable for one epehemeris
            e=ephData.(signal);
            
            % Set week number from ephemeris
            if isfield(e, 'weekNumber') % TBA If GLONASS, no week number
                obs.(signal).channel(channelNr).week = e(prn).weekNumber;
                if(obs.(signal).channel(channelNr).week < 1024)
                    obs.(signal).channel(channelNr).week = obs.(signal).channel(channelNr).week + 1024;
                end
            end
            
            % Calculate position dependent satellite info
            if(strcmp(navSolution.Pos.Flag,'GOOD_FOR_NAV') == 1) 
                carrFreq = obs.(signal).channel(channelNr).carrierFreq;
                pos = navSolution.Pos.xyz;  
                
                [doppler,el,az] = ...
                    getSatelliteDoppler(allSettings.const, carrFreq, sat.(signal).channel(channelNr), pos);
                sat.(signal).channel(channelNr).doppler = doppler;
                sat.(signal).channel(channelNr).elev = el;
                sat.(signal).channel(channelNr).azim = az;     
            end             
            
        end
    end
end