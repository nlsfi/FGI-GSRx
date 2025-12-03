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
function showNavStatus(allSettings, epoch, navSolution, obs, sat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prints the status of navigation to the command window
%
% Inputs:
%   allSettings     - receiver configuration settings
%   epoch           - Current epoch number
%   navSolutions    - Output from navigation (position, velocity, time,
%   obs             - Observations for one epoch
%   sat             - satellite positions and velocities for one epoch
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;

% Total number of satellites used from all signals
totalSatUsed = sum(navSolution.Pos.nrSats);

fprintf('\n================================================================================\n');
fprintf('Processed epoch: %d\n',epoch);
fprintf('Number of Satellites   ');

% Print number of satellites for each signal
for i=1:length(navSolution.Pos.nrSats)
    if(navSolution.Pos.nrSats(i) > 0)
        fprintf('   %s: %d',navSolution.Pos.signals{i}, navSolution.Pos.nrSats(i));
    end
end
fprintf('\n');
fprintf('Total number of satellites: %d\n',totalSatUsed);
if(totalSatUsed == 0)
    return;
end

fprintf('=========================== LSE solution ============================================\n');
fprintf('\n');
navSolution.Pos;
fprintf('Navigation status: %s\n',navSolution.Pos.Flag);
fprintf('********************Time***************************\n');
fprintf('* Signal   tow(s)        Bias(ms)    Drift(ms/s) *\n');
for i=1:length(navSolution.Time.receiverTow)
    fprintf('* %5s  %10.4f %10.4f %12.5f        *\n',navSolution.Pos.signals{i}, navSolution.Time.receiverTow(i), 1e3*navSolution.Pos.dt(i), 1e3*navSolution.Vel.df(i));
end

fprintf('***************************************************\n');
fprintf('********************DOP******************\n');
fprintf('* GDOP: %4.2f  PDOP: %4.2f  HDOP: %4.2f    *\n',navSolution.Pos.dop(1),navSolution.Pos.dop(2),navSolution.Pos.dop(3));
fprintf('* VDOP: %4.2f  TDOP: %4.2f                *\n',navSolution.Pos.dop(4),navSolution.Pos.dop(5));
fprintf('*****************************************\n');
fprintf('********************Position********************************\n');
fprintf('* X: %6.2f  Y: %6.2f  Z: %6.2f  Fom: %4.2f   *\n',navSolution.Pos.xyz(1),navSolution.Pos.xyz(2),navSolution.Pos.xyz(3),navSolution.Pos.fom);
fprintf('* dE: %6.2f  dN: %6.2f  dU: %6.2f   *\n',navSolution.Pos.enu(1),navSolution.Pos.enu(2),navSolution.Pos.enu(3));    
fprintf('************************************************************\n');
fprintf('********************Velocity*********************\n');
fprintf('VX: %6.2f  VY: %6.2f  VZ: %6.2f  Fom: %4.2f   *\n',navSolution.Vel.xyz(1),navSolution.Vel.xyz(2),navSolution.Vel.xyz(3),navSolution.Vel.fom);
fprintf('*************************************************\n');


