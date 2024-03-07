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
function tR = beib1BitSync(signalSettings,tR,ch)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bit sync function for Beidou B1 signal
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

if((loopCnt < 200)|| (trackChannelData.bitSync == 1)) || mod(loopCnt,20)~=0
    return; % Nothing to do yet
end

% TBA later
if trackChannelData.SvId.satId < 6 % Do only for IGSO and MEO satellites. does not really matter for GEO satellites, as the bit duration is only 2 msec
   trackChannelData=beiDouGEOBitSync(trackChannelData,loopCnt);   
else
    NHcorr = calcCrossCorrelation(sign(trackChannelData.I_P(1:loopCnt)),signalSettings.secondaryCode);
    NHcorr = fliplr(NHcorr);
    indexNH20 = find(abs(abs(NHcorr)-20)<0.1);  
    diffIndexVal = indexNH20(end:-1:2)-indexNH20(end-1:-1:1);  

    if sum(rem(diffIndexVal(:),20))==0 && isempty(indexNH20)==0 && isempty(diffIndexVal)==0 && length(indexNH20)>=8                                                      
         trackChannelData.bitBoundaryIndex = mod(20-(indexNH20(1)-20)+1,20);                        
        if trackChannelData.bitBoundaryIndex==0            
            trackChannelData.bitBoundaryIndex=20;                
        end            
            % Check whether bitSync is really successfull by looking at
            % the I_P correlation values: they should have at least same
            % sign for 20 ms
            dataBit = trackChannelData.I_P((loopCnt+trackChannelData.bitBoundaryIndex)-40:(loopCnt+trackChannelData.bitBoundaryIndex)-21).*signalSettings.secondaryCode;
            if abs(sum(sign(dataBit)))==20
                trackChannelData.bitSync=1;                                                     
                disp(['   Bit sync for BeiDou prn ', ...
                    int2str(trackChannelData.SvId.satId),' found at ',int2str(loopCnt), ' with index ', int2str(trackChannelData.bitBoundaryIndex)]);
            end                                                     
    end
end                

% Copy updated local variables
tR.channel(ch) = trackChannelData;
    
