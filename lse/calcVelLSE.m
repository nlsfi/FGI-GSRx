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
function Vel = calcVelLSE(obs, sat, allSettings, Vel, Pos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function calculates the Least Square Solution
%
% Inputs:
%   obs             - Observations for one epoch
%   sat             - Satellite positions and velocities for one epoch
%   allSettings     - receiver settings
%   Vel             - receiver velocity and receiver clock drift
%   pos             - Initial position for the LSE 
%
% Outputs:
%   Vel             - receiver velocity and receiver clock drift
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set starting point
Vel.bValid = false;
pos = Pos.xyz;
vel = Vel.xyz;

% Constants
SPEED_OF_LIGHT = allSettings.const.SPEED_OF_LIGHT;

% Temporary variables
nmbOfIterations = 10;

% Total number of signals enabled
nrOfSignals = allSettings.sys.nrOfSignals;

% Init clock elements in vel vector
vel(4:3+nrOfSignals) = zeros;

%nrSatsUsed = zeros(1,length(obs));

% Iteratively find receiver velocity
for iter = 1:nmbOfIterations
    ind = 0;    
    
    % Loop over all signals
    for signalNr = 1:allSettings.sys.nrOfSignals
        
        % Extract signal acronym
        signal = allSettings.sys.enabledSignals{signalNr};        
        
        % Loop over all channels
        for channelNr = 1:obs.(signal).nrObs

            if(obs.(signal).channel(channelNr).bObsOk)
                ind = ind + 1; % Index for valid obervations
            
                % These are the dopplers for all satellites
                pseudo_range_rate(ind) = obs.(signal).channel(channelNr).doppler;
                
                % Calculate range to satellite    
                dx=sat.(signal).channel(channelNr).Pos(1)-pos(1);
                dy=sat.(signal).channel(channelNr).Pos(2)-pos(2);
                dz=sat.(signal).channel(channelNr).Pos(3)-pos(3);
                range(ind)=sqrt(dx^2+dy^2+dz^2); 

                % Direction cosines
                sv_matrix(ind,1) = dx/range(ind);
                sv_matrix(ind,2) = dy/range(ind);
                sv_matrix(ind,3) = dz/range(ind);
                sv_matrix(ind,3+signalNr) = 1;
                
                relative_velocity(ind) = dx * sat.(signal).channel(channelNr).Vel(1) + dy * sat.(signal).channel(channelNr).Vel(2) + dz * sat.(signal).channel(channelNr).Vel(3);
                relative_velocity(ind) = relative_velocity(ind) / sqrt(dx*dx+dy*dy+dz*dz);

                % Observed minus predicted
                omp.dRange_rate(ind) = pseudo_range_rate(ind) + relative_velocity(ind) + sat.(signal).channel(channelNr).Vel(4) * SPEED_OF_LIGHT;

                Res(ind) = omp.dRange_rate(ind) - vel(3 + signalNr)*SPEED_OF_LIGHT;                
                
            end
        end
        nrSatsUsed(signalNr) = ind;
        
    end

    % This is the actual solutions to the LSE optimisation problem
    clear H;
    clear dR;    
    H=sv_matrix;
    dR=omp.dRange_rate;
    DeltaVel=(H'*H)^(-1)*H'*dR';

    % Updating the position with the solution
    vel(1)=DeltaVel(1);
    vel(2)=DeltaVel(2);
    vel(3)=DeltaVel(3);

    % Update the clock offsets for all systems
    vel(4:end) = DeltaVel(4:end)/SPEED_OF_LIGHT;

end    

% Copying data to output data structure
Vel.dopplerResid = Res;
Vel.nrSats = nrSatsUsed;
Vel.xyz = vel(1:3);
Vel.df = vel(4:end);
Vel.fom = norm(Res/length(Res));

% Check if solution is valid
if(Vel.fom < 5000)
    Vel.bValid = true;
end
 
 
