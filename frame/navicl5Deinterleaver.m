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

function deinterleavedSubFrame = navicl5Deinterleaver(subFrame)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function deinterleaves the incoming 600-bit subframe.
%
%   Inputs:
%       subFrame    - one sub Frame (600 bits)
%
%   Outputs:
%       deinterleavedSubFrame - 584-bit deinterleaved subframe data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


deinterleavedSubFrame = zeros(1,584);
deinterleavingMatrix = zeros(8,73);
%if we find a sync word in the first 16 bits of the incoming word, the
%subframe data is OK. Remove these first 16 bits before proceeding to
%the deinterleaving
if isequal(subFrame(1:16),[1 1 1 0 1 0 1 1 1 0 0 1 0 0 0 0]) == 1
    
    %truncate the sync word
    subFrame = subFrame(17:end);
    %now deinterleave. Arrange the data along the rows and read
    %in columns (opposite as the interleaving described in NAVIC ICD)
    rowNum = 1;
    colNum = 1;
    for bitNum = 1:1:length(subFrame)
        deinterleavingMatrix(rowNum, colNum) = subFrame(bitNum);
        colNum = colNum+1;
        if(colNum == 74)
            rowNum = rowNum+1;
            colNum = 1;
        end
    end
    rowNum = 1;
    colNum = 1;
    for bitNum = 1:1:length(subFrame)
        deinterleavedSubFrame(bitNum) = deinterleavingMatrix(rowNum, colNum);
        rowNum = rowNum+1;
        if(rowNum == 9)
            rowNum = 1;
            colNum = colNum+1;
        end
    end
elseif isequal(subFrame(1:16),[0 0 0 1 0 1 0 0 0 1 1 0 1 1 1 1]) == 1
    %subframe found in flipped state. flip all bits
    subFrame = ~subFrame;

    %truncate the sync word
    subFrame = subFrame(17:end);
    %now deinterleave. Arrange the data along the rows and read
    %in columns (opposite as the interleaving described in NAVIC ICD)
    rowNum = 1;
    colNum = 1;
    for bitNum = 1:1:length(subFrame)
        deinterleavingMatrix(rowNum, colNum) = subFrame(bitNum);
        colNum = colNum+1;
        if(colNum == 74)
            rowNum = rowNum+1;
            colNum = 1;
        end
    end
    rowNum = 1;
    colNum = 1;
    for bitNum = 1:1:length(subFrame)
        deinterleavedSubFrame(bitNum) = deinterleavingMatrix(rowNum, colNum);
        rowNum = rowNum+1;
        if(rowNum == 9)
            rowNum = 1;
            colNum = colNum+1;
        end
    end
else
    disp('NAVIC L5 Sync Word NOT found.');
    return;
end
end