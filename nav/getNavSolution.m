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
function [obs, sat, navSolution] = getNavSolution(obs, sat, navSolution, allSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function calculates navigation solutions for the receiver. 
%
% Inputs:
%   obs             - Observations for one epoch
%   sat             - satellite positions and velocities for one epoch
%   navSolution     - Current navigation solution 
%   allSettings     - receiver settings.
%   ephData         -  ephemeris data for all systems
%
% Outputs:
%   obsSingle       - Observations for one epoch
%   satSingle       - satellite positions and velocities for one epoch
%   navSolutions    - Output from navigation (position, velocity, time,
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Init Pos and Vel with those from the previous epoch
Pos = navSolution.Pos;
Vel = navSolution.Vel;

% Check if we have enough observations for a nav solution
trynav = checkIfNavIsPossible(obs, allSettings);

if (trynav)
    % Calculate receiver position 
    Pos = calcPosLSE(obs, sat, allSettings, Pos);

    % Calculate receiver velocity solution
    Vel = calcVelLSE(obs, sat, allSettings, Vel, Pos);
    
    % Update observation structure
    obs = updateObservations(obs, Pos, Vel, allSettings);

    % Coordinate conversion 
    [Pos.LLA(1),Pos.LLA(2),Pos.LLA(3)] = wgsxyz2lla(allSettings.const, Pos.xyz);  

    % Update time estimates from fix
    Time = updateReceiverTime(Pos, obs, allSettings);

else 
    % There are not enough satellites to find 3D position 
    disp(': Not enough information for position solution.');

    if(allSettings.osnma.enableOSNMA==0)
        % Copy whatever data we have and set rest to NaN
        lengthdop = 4 + allSettings.sys.nrOfSignals;
       
        Pos.xyz  = zeros(1,3);
        Pos.LLA = zeros(1, 3);
        Pos.fom = NaN;
        Pos.dop = zeros(1, lengthdop);
        Pos.trueRange = NaN;
        Pos.rangeResid = NaN;
        Pos.nrSats = NaN;
        Pos.dt = NaN;
        Pos.bValid = false;
        Pos.Flag = NaN;
    
        Vel.xyz = zeros(1,3);
        Vel.fom = NaN;
        Vel.dopplerResid = NaN;
        Vel.nrSats = NaN;
        Vel.df = NaN;
        Vel.bValid = false;
    end

    Time.receiverTow = NaN;
end

navSolution.Pos = Pos;
navSolution.Vel = Vel;
navSolution.Time = Time;


