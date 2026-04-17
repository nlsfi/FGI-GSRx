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
function cmps(obj, fileId, r3nh ,ii)
% CMPS composes the data to the RINEX file.
%
% Inputs:
%   obj:rinex3NavData
%   fileId:fid
%   r3nh:rinex3NavHeader
%   ii:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if ~obj.isValid(r3nh)
        error('rinex3NavData:invalid', ...
              'The contents of this block do not qualify.');
    end

    % Extract the struct from cell
    data = obj.observations{1};

    sysChar = data.sysChar;
    prn = data(ii).prn;
    t = data(ii).epochTime;
    af0 = data(ii).clockBias;
    af1 = data(ii).clockDrift;
    af2 = data(ii).clockDriftRate;

    line = sprintf('%1s%02d %4d %02d %02d %02d %02d %02d%19.12E%19.12E%19.12E\n', ...
        sysChar, prn, year(t), month(t), day(t), hour(t), minute(t), floor(second(t)), af0, af1, af2);
    fprintf(fileId, line);

    orbitFields = {'orbit1','orbit2','orbit3','orbit4','orbit5','orbit6', 'orbit7'};
    for k = 1:numel(orbitFields)-1
        vals = data(ii).(orbitFields{k});
        if numel(vals) < 4, vals(end+1:4) = 0; end
        fprintf(fileId, '    %19.12E%19.12E%19.12E%19.12E\n', vals(1), vals(2), vals(3), vals(4));
    end
    vals = data(ii).(orbitFields{7});
    fprintf(fileId, '    %19.12E%19.12E\n', vals(1), vals(2));

end