%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2015-2026 Finnish Geospatial Research Institute FGI, National
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
function tsCorr = getTimesysCorr(ephData)
% GETTIMESYSCORR Get the needed data for time system corrections.
%
% Input:
%   ephData:struct
%
% Output:
%   tsCorr:struct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tsCorr = struct();

    % GPUT
    if isfield(ephData,'gpsl1') && ~isempty(ephData.gpsl1)        
        % GSRx doesnt decode subframes 4 or 5 currently.
    end

    % GAUT
    if isfield(ephData,'gale1b') && ~isempty(ephData.gale1b)

        e = ephData.('gale1b');
        % Find entries with a non-empty 'subframe' field with subframe ok
        validIdx = find(arrayfun(@(x) isfield(x, 'subframe') && ~isempty(x.subframe) && ...
                    any(arrayfun(@(sf) isfield(sf,'subframeOk') && ...
                    any(sf.subframeOk==1), x.subframe(:))), e));
        
        % take the first
        eph = e(validIdx(1)).subframe; 

        tsCorr.gal.label = 'GAUT';
        tsCorr.gal.a0   = eph.A0;
        tsCorr.gal.a1   = eph.A1;
        tsCorr.gal.tref = eph.t_ot;
        tsCorr.gal.week = eph.WN_ot;
        tsCorr.gal.src  = sprintf('E%02d', validIdx(1));
        tsCorr.gal.utcId = 0;   % unknown?
    end
    
end


