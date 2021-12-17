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
function [wide,narrow] = narrowWidePower(tC,signal,startBitInd,endBitInd)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate narrow and wide band power for 
%
% Input: 
%   tC                  - Results from signal tracking for one channel
%   signal              - Signal acronym
%   startBitInd         - Index of bit to start from
%   endBitInd           - Index of bit to end at
%
% Output:
%   wide                - Wide band power
%   narrow              - Narrow band power
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

               
if strcmp(signal,'gale1b') || strcmp(signal,'gale1c') || strcmp(signal,'beib1')       
    corrIntervalEpoch = tC.Nc*1000;
    startBitInd=startBitInd+corrIntervalEpoch-1;
    
    % Calculate wide band power
    wide = sum(tC.I_P(startBitInd:corrIntervalEpoch:endBitInd).^2 ... 
                       + tC.Q_P(startBitInd:corrIntervalEpoch:endBitInd).^2);
    % Calculate narrow band power
    narrow = sum(abs(tC.I_P(startBitInd:corrIntervalEpoch:endBitInd)))^2 ...
                   + sum(abs(tC.Q_P(startBitInd:corrIntervalEpoch:endBitInd)))^2; 
else
    % Calculate wide band power
    wide = sum(tC.I_P(startBitInd:endBitInd).^2 ... 
                       + tC.Q_P(startBitInd:endBitInd).^2);
    % Calculate narrow band power
    narrow = sum(tC.I_P(startBitInd:endBitInd))^2 ...
                       + sum(tC.Q_P(startBitInd:endBitInd))^2; 
end
                       
                       
                       
                       