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
function Pos = calcPosLSE(obs, sat, allSettings, Pos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function calculates the Least Square Solution
%
% Inputs:
%   obs             - Observations for one epoch
%   sat             - Satellite positions and velocities for one epoch
%   allSettings     - receiver settings
%   pos             - Initial position for the LSE 
%
% Outputs:
%   Pos             - receiver position and receiver clock error
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set starting point
pos = Pos.xyz;
Pos.bValid = false;

% Constants
WGS84oe = allSettings.const.EARTH_WGS84_ROT;
SPEED_OF_LIGHT = allSettings.const.SPEED_OF_LIGHT;

% Temporary variables
rcvr_clock_corr = 0;
nmbOfIterations = 10;

% Total number of signals enabled
nrOfSignals = allSettings.sys.nrOfSignals;

% Init clock elements in pos vector
pos(4:3+nrOfSignals) = zeros;

%nrSatsUsed = zeros(1,length(obs));

% Iteratively find receiver position 
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
                pseudo_range(ind) = obs.(signal).channel(channelNr).corrP;
                            
                % Calculate range to satellite
                dx=sat.(signal).channel(channelNr).Pos(1)-pos(1);
                dy=sat.(signal).channel(channelNr).Pos(2)-pos(2);
                dz=sat.(signal).channel(channelNr).Pos(3)-pos(3);                
                range(ind)=sqrt(dx^2+dy^2+dz^2); % This is the calculated range to the satellites

                % Direction cosines
                sv_matrix(ind,1) = dx/range(ind);
                sv_matrix(ind,2) = dy/range(ind);
                sv_matrix(ind,3) = dz/range(ind);
                sv_matrix(ind,3+signalNr) = 1;
                
                % Total clock correction term (m). */
                %clock_correction = c*(sv_pos.dDeltaTime - eph(info.PRN).group_delay);
                clock_correction = 0;
                
                % First compute the SV's earth rotation correction
                rhox = sat.(signal).channel(channelNr).Pos(1) - pos(1);
                rhoy = sat.(signal).channel(channelNr).Pos(2) - pos(2);
                EarthRotCorr(ind) = WGS84oe / SPEED_OF_LIGHT * (sat.(signal).channel(channelNr).Pos(2)*rhox-sat.(signal).channel(channelNr).Pos(1)*rhoy);

                % Total propagation delay.
                propagation_delay(ind) = range(ind) + EarthRotCorr(ind) - clock_correction;

                % Correct the pseudoranges also (because we corrected rcvr stamp)
                pseudo_range(ind)  = pseudo_range(ind) - SPEED_OF_LIGHT*rcvr_clock_corr;
                omp.dRange(ind)    = pseudo_range(ind) - propagation_delay(ind);
                Res(ind) = omp.dRange(ind) - pos(3 + signalNr)*SPEED_OF_LIGHT;                
                
            end
        end
        nrSatsUsed(signalNr) = ind;
    end
     
    % This is the actual solutions to the LSE optimisation problem
    clear H;
    clear dR;    
    H=sv_matrix;%(1:5,:);
    dR=omp.dRange;%(1:5);
    DeltaPos=(H'*H)^(-1)*H'*dR';

    % Updating the position with the solution
    pos(1)=pos(1)-DeltaPos(1);
    pos(2)=pos(2)-DeltaPos(2);
    pos(3)=pos(3)-DeltaPos(3);
    
    % Update the clock offsets for all systems
    pos(4:end) = DeltaPos(4:end)/SPEED_OF_LIGHT; % In seconds
end    

% Copying data to output data structure
Pos.trueRange = range;
Pos.rangeResid = Res;
Pos.nrSats = diff([0 nrSatsUsed]);
Pos.signals = allSettings.sys.enabledSignals;
Pos.xyz = pos(1:3);
Pos.dt = pos(4:end);

% Get dop values
Pos.dop = getDOPValues(allSettings.const,H, Pos.xyz);

% Calculate fom
Pos.fom = norm(Res/length(Res));

% Check if solution is valid
if(Pos.fom < 50)
    Pos.bValid = true;
end
 
 
 


