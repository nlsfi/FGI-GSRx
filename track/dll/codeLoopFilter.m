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
function tR = codeLoopFilter(signalSettings,tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code tracking loop filter
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
loopCnt = tR.loopCnt;
if(trackChannelData.bInited)
    oldCodeNco   = trackChannelData.prevCodeNco;
    oldCodeError = trackChannelData.prevCodeError;    
else
    oldCodeNco   = 0;
    oldCodeError = 0;         
end
tau1code = trackChannelData.tau1code;
tau2code = trackChannelData.tau2code;
PDIcode = tR.PDIcode;
codeFreqBasis = signalSettings.codeFreqBasis;

% Calculate code error from discriminator function
codeError = trackChannelData.dllDiscr(loopCnt);
trackChannelData.codeError = codeError;   

% Calculate NCO feedback
codeNco = oldCodeNco + (tau2code/tau1code) * ...
    (codeError - oldCodeError) + codeError * (PDIcode/tau1code);
trackChannelData.codeNco = codeNco;            

% Calcualte code frequency
codeFreq = codeFreqBasis - codeNco + ( (trackChannelData.carrFreq(loopCnt) - trackChannelData.intermediateFreq)/trackChannelData.carrToCodeRatio );
trackChannelData.codeFreq = codeFreq;
trackChannelData.prevCodeFreq = codeFreq;

% Store values for next round
trackChannelData.prevCodeNco = codeNco;
trackChannelData.prevCodeError = codeError;   


% Copy updated local variables
tR.channel(ch) = trackChannelData;



