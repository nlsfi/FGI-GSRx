%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FGI-GSRx software GNSS receiver
%
% Finnish Geospatial Research Institute
% Department of Navigation and Positioning
% DO NOT DISTRIBUTE
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function obs = preambleConsistencyCheck(tR, obs, signalSettings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function performs a consistency check whether all the subframes point to
% the same subframe beginning
%
% Inputs:
%   tR              - Tracking results for a specific signal
%   obs             - Observations for a specific signal
%   signalSettings  - Signal settings
%
% Outputs:
%   obs             - Observations for a specific signal
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for channelNr = 1:tR.nrObs
    firstSubFrames(channelNr) = obs.channel(channelNr).firstSubFrame;
end
if (max(firstSubFrames)-min(firstSubFrames)) >= signalSettings.preambleIntervall/2 %subFrame/page length of each system, for Galileo it is 250 symbols
    differenceInFirstSubFrame = max(firstSubFrames)-firstSubFrames;
    indices = find(differenceInFirstSubFrame >= signalSettings.preambleIntervall/2);
    subFrameEpochPassedInSec  = round(differenceInFirstSubFrame/signalSettings.preambleIntervall);
    firstSubFrames(indices) = firstSubFrames(indices)+signalSettings.preambleIntervall*subFrameEpochPassedInSec(indices);
    for channelNr = 1:tR.nrObs
        obs.channel(channelNr).firstSubFrame = firstSubFrames(channelNr);
    end
end


