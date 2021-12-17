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

% Init temporary variables
[Pos, Vel, Time] = initPosVel(navSolution);

% Check if we have enough observations for a nav solution
trynav = checkIfNavIsPossible(obs, allSettings);

if (trynav)
    
    Pos.xyz = navSolution.Pos.xyz;
    Pos.bValid = false;
    Vel.xyz = navSolution.Vel.xyz;
    Vel.bValid = false;
    
    % Calculate receiver position 
    [Pos] = calcPosLSE(obs, sat, allSettings, Pos); 
    
    % Update if valid
    if(Pos.bValid == true)
        navSolution.Pos = Pos;
    end
  
    % Calculate receiver velocity solution
    [Vel] = calcVelLSE(obs, sat, allSettings, Vel, Pos);   

    % Update if valid
    if(Vel.bValid == true)
        navSolution.Vel = Vel;
    end
    
    % Update observation structure
    obs = updateObservations(obs, Pos, Vel, allSettings);

    % Coordinate conversion 
    [Pos.LLA(1),Pos.LLA(2),Pos.LLA(3)] = wgsxyz2lla(allSettings.const, Pos.xyz);

    % TBA enu calculations
    %[reflat,reflon,refalt] = wgsxyz2lla([settings.truePosition.X settings.truePosition.Y settings.truePosition.Z]);
    %navSolution.LSE.enu = wgsxyz2enu(navSolution.LSE.Pos.XYZ(1:3), reflat, reflon, refalt);    

    % Update time estimates from fix
    Time = updateReceiverTime(Pos, obs, allSettings);

else 
    % There are not enough satellites to find 3D position 
    disp(': Not enough information for position solution.');

    % Copy whatever data we have and set rest to NaN
    nrOfSignals = allSettings.sys.nrOfSignals;
    lengthdop=4+nrOfSignals;
    navSolution.LSE.Pos.XYZ  = [0 0 0];
    navSolution.LSE.Pos.dt  = NaN;
    navSolution.LSE.Pos.fom  = NaN;
    navSolution.LSE.DOP  = zeros(1,lengthdop);
    navSolution.LSE.Vel.XYZ  = [0 0 0];
    navSolution.LSE.Vel.df  = NaN;
    navSolution.LSE.Vel.fom  = NaN;
    navSolution.LSE.Systems  = NaN;        
    navSolution.LSE.FixStatus  = 'LKG';    
    navSolution.Klm.FixStatus  = 'LKG';        
    navSolution.nrSatUsed = 0;  
    navSolution.totalSatUsed = 0;
    navSolution.Time.receiverTow = NaN;
    
    navSolution.LSE.LLA  = [0 0 0];
    navSolution.LSE.enu  = [0 0 0];
    navSolution.Klm.LLA  = [0 0 0];

end

navSolution.Pos = Pos;
navSolution.Vel = Vel;
navSolution.Time = Time;

% TBA This is the sample count for this epoch and for this fix
%navSolution.sampleCount = obsSingle.sampleCount;

