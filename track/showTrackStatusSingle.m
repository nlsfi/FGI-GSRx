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
function showTrackStatusSingle(tR, allSettings, loop)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Prints the status of all track channels to the command window
%
% Inputs:
%   allSettings     - Receiver settings
%   tR              - Results from signal tracking for all signals
%   loop            - Epoch counter value
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~allSettings.sys.showTrackingOutput
    return % Do not show the tracking output
end

fprintf('\n*======*===========*=====*===============*===========*========*=========================*\n');
fprintf(  '|  Ch  |  Signal   | PRN |   Frequency   |  Doppler  | Power  |  State                  |\n');
fprintf(  '*======*===========*=====*===============*===========*========*=========================*\n');

% Loop over all signals
for signalNr = 1:allSettings.sys.nrOfSignals
    
    % Extract signal acronym
    signal = tR.signal;    
    
    % Loop over all channels
    for channelNr = 1:tR.(signal).nrObs 
        snr = tR.(signal).channel(channelNr).meanCN0fromSNR(loop);              

        fprintf('|  %2d  ',channelNr);
        fprintf('|  %6s   ',tR.(signal).signal);
        fprintf('| %3d ',tR.(signal).channel(channelNr).SvId.satId);
        if(tR.(signal).channel(channelNr).carrFreq(loop) < 0)
            fprintf('| %2.5e  ', tR.(signal).channel(channelNr).carrFreq(loop));
        else
            fprintf('|  %2.5e  ', tR.(signal).channel(channelNr).carrFreq(loop));
        end
        if(tR.(signal).channel(channelNr).doppler(loop) < 0)    
            fprintf('|  %5.0f    ' ,tR.(signal).channel(channelNr).doppler(loop));
        else
            fprintf('|   %5.0f   ' ,tR.(signal).channel(channelNr).doppler(loop));
        end
        fprintf('| %5.0f  ' ,snr);  
        fprintf('|   %21s |\n' ,tR.(signal).channel(channelNr).trackState);  

    end
end

fprintf(  '*======*===========*=====*========*===============*===========*========*=========================*\n');
