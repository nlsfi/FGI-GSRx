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
function obs = checkOSNMAObservations(obs,sat)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function decides which observations are going to be used in
% navigation based on OSNMA ADKD0 verifcation
%
% Inputs:
%   obs             - structure with observations for one measurement epochs
%   sat             - structure with satellite info for one epochs

% Outputs:
%   obs             - structure with observations for one measurement epochs
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract signal acronym
signal='gale1b'; %OSNMA is only avaiable for Galileo E1B signals


for channelNr = 1:obs.(signal).nrObs   
    if(obs.(signal).channel(channelNr).OSNMA.OSNMAEnable==1)
        if(obs.(signal).channel(channelNr).bObsOk==1)
                ind=find(obs.(signal).channel(channelNr).OSNMA.time_lapse==floor(sat.(signal).channel(channelNr).refTime));
                if(~isempty(ind))   
                    if(~isnan(obs.(signal).channel(channelNr).OSNMA.AuthenticationFailed_ADKD0(ind)))
                        obs.(signal).channel(channelNr).bObsOk = false;
                    end
                else
                    obs.(signal).channel(channelNr).bObsOk = false; %OSNMA has not yet been authenticated due to rootkey validation latency. This could be in the start of the measuremnet and at the end as well.
                end
        end
    else
        obs.(signal).channel(channelNr).bObsOk = false;%incase of not authentication no navigation data is generated.
    end
end