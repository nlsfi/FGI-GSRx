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
function tR = freqDiscrimAtan2(tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Atan2 frequency discriminator function
%
% Inputs:
%   tR             - Results from signal tracking for one signals
%   ch             - Channel index
%
% Outputs:
%   tR             - Results from signal tracking for one signals
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set local variables
trackChannelData = tR.channel(ch);
loopCnt = trackChannelData.loopCnt;
IP_2 = trackChannelData.I_P(loopCnt);
QP_2 = trackChannelData.Q_P(loopCnt);
step = trackChannelData.Nc*1000;
if(trackChannelData.bInited)
    IP_1 = trackChannelData.I_P(loopCnt-step);
    QP_1 = trackChannelData.Q_P(loopCnt-step);    
else
    IP_1 = trackChannelData.Nc;
    QP_1 = trackChannelData.Nc;    
end


% Calcualte dot and cross products
dot   = (IP_1*IP_2 + QP_1*QP_2);
cross = (IP_1*QP_2 - IP_2*QP_1);

% Compute frequency error (atan2 discriminator)
freqError = atan2(cross,dot)/(2.0*pi);

% Accumulate FLL discriminator
if(trackChannelData.bInited)
    trackChannelData.fllDiscr(loopCnt) = freqError;    
else
    trackChannelData.fllDiscr(loopCnt) = 0;
end


% Copy updated local variables
tR.channel(ch) = trackChannelData;
