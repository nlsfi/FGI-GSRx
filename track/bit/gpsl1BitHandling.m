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
function tR = gpsl1BitHandling(tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extract GPS bits
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

% Sum over 20 last samples
% TBA. Set to -1 and 1 as for Galileo
if (mod(loopCnt,20)==0)
    trackChannelData.bitValue(loopCnt) = sum(trackChannelData.I_P(loopCnt-19:loopCnt));
end

% For bit boundary detection
if(loopCnt > 1)
    bitflip = sign(trackChannelData.I_P(loopCnt) * trackChannelData.I_P(loopCnt - 1)); 
    if(bitflip < 0)
        ind = mod(loopCnt,20);
        if(ind==0)
            ind=20;
        end
        trackChannelData.bithist(ind) = trackChannelData.bithist(ind) + 1;
    end
    % Check if we have bit sync
    val = sort(trackChannelData.bithist,'descend');
    if((val(1)-val(2)) > 32)
        trackChannelData.bitLock = 1;
    end
    indexLow = find(trackChannelData.bithist > 20);
    if(length(indexLow) > 1)
        trackChannelData.bitLock = 0;        
    end
    
end

% Copy updated local variables
tR.channel(ch) = trackChannelData;



