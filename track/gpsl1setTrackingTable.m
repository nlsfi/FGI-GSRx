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
function tC = gpsl1setTrackingTable(tC, trackState)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialises tracking table for gps signals
%
% Inputs:
%   tC          - Results from signal tracking for one channel
%   trackState  - Tracking state of channel
%
% Outputs:
%   tC          - Results from signal tracking for one channel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set functions to be executed for each defined mode
switch(trackState)
    case 'STATE_PULL_IN'
        tC.trackTable =...
            {'CN0fromSNR',1;...            
            'freqDiscrimAtan2',1;...
            'freqLoopFilterWide',1;...            
            'phaseDiscrim',1;...
            'phaseLoopFilterWide',1;...
            'bitSync',20;...
            'phaseFreqFilter',1;...
            'codeDiscrim',1,;...
            'codeLoopFilter',1;...
            'lockDetect',1;...
            'gpsl1UpdateChannelState',1};
case 'STATE_COARSE_TRACKING'
        tC.trackTable =...
            {'CN0fromSNR',1;...            
            'freqDiscrimAtan2',1;...
            'freqLoopFilterNarrow',1;...            
            'phaseDiscrim',1;...
            'phaseLoopFilterNarrow',1;...
            'bitSync',20;...
            'phaseFreqFilter',1;...            
            'codeDiscrim',1,;...
            'codeLoopFilter',1;...
            'lockDetect',1;...
            'gpsl1UpdateChannelState',1};        
    case 'STATE_FINE_TRACKING'
        tC.trackTable =...
            {'CN0fromSNR',1;...                        
            'freqDiscrimAtan2',1;...
            'freqLoopFilterVeryNarrow',1;...            
            'phaseDiscrim',1;...
            'phaseLoopFilterVeryNarrow',1;...
            'bitSync',20;...
            'phaseFreqFilter',1;...            
            'codeDiscrim',1,;...
            'codeLoopFilter',1;...
            'lockDetect',1;...
            'gpsl1UpdateChannelState',1};
end








