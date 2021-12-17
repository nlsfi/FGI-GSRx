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
function tR = CN0fromSNR(tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function for estimating CNO values using SNR
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
I_P = trackChannelData.I_P(loopCnt);
Q_P = trackChannelData.Q_P(loopCnt);
I_E_E = trackChannelData.I_E_E(loopCnt);
Q_E_E = trackChannelData.Q_E_E(loopCnt);

% Calculate current noise level
trackChannelData.noiseCNOfromSNR(loopCnt) = I_E_E + Q_E_E;
intervalEpoch = trackChannelData.Nc*1000;
 if loopCnt>1000 
    iCount = loopCnt-1000+intervalEpoch;    
    noiseLevel = trackChannelData.noiseCNOfromSNR(iCount:intervalEpoch:loopCnt); 
 else
    noiseLevel = trackChannelData.noiseCNOfromSNR(intervalEpoch:intervalEpoch:loopCnt);
 end

if(trackChannelData.bInited)
    noiseVariance = sum((noiseLevel-mean(noiseLevel)).^2)/length(noiseLevel); % Variance of noise level
    signalPower = I_P.^2 + Q_P.^2; % Signal power
    if loopCnt>intervalEpoch
        % Fill up the first C/N0 estimate with the 2nd C/N0 estimate: just
        % to avoid putting zero for the first estimate
        trackChannelData.CN0fromSNR(intervalEpoch)=10*log10(((signalPower)/noiseVariance)/trackChannelData.PDIcode);    
    end
    
    % Calculate CN0 from SNR using log10
    trackChannelData.CN0fromSNR(loopCnt)=10*log10(((signalPower)/noiseVariance)/trackChannelData.PDIcode);  

    % Calculate sliding mean and variance 
    if loopCnt>1000 
       jCount = loopCnt-1000+intervalEpoch;
       trackChannelData.varianceCNOfromSNR(loopCnt) =  var(trackChannelData.CN0fromSNR(jCount:intervalEpoch:loopCnt));
       trackChannelData.meanCN0fromSNR(loopCnt)=mean(trackChannelData.CN0fromSNR(jCount:intervalEpoch:loopCnt));    
    else
        trackChannelData.varianceCNOfromSNR(loopCnt)    = var(trackChannelData.CN0fromSNR(intervalEpoch:intervalEpoch:loopCnt));
        trackChannelData.meanCN0fromSNR(loopCnt)=mean(trackChannelData.CN0fromSNR(intervalEpoch:intervalEpoch:loopCnt));    
    end      

end 

% Copy updated local variables
tR.channel(ch) = trackChannelData;