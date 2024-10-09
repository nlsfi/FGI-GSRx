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
function [level, variance] = momEstimator(syms, nWin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The function estimates symbol level and variances using a method of moments
%
% Input:
%   syms        - Input, assumed Gaussian, BPSK symbols
%   nWin        - Moving average window length
%
% Output:
%   level       - Estimated symbol level
%   variance    - Estimated symbol variance
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Moving filter
filt = ones(nWin,1)/nWin;

% Squared input symbols
sqSyms = syms.^2;

% Moving average of squared input symbol
meanSqSyms = filter(filt,1,sqSyms);

% Moving variance
varSqSyms = filter(filt,1,(sqSyms-meanSqSyms).^2);

% Skip initial symbols
meanSqSyms   = meanSqSyms(nWin+1:end);
varSqSyms    = varSqSyms(nWin+1:end);

% Symbol variance and level
variance = meanSqSyms-sqrt(meanSqSyms.^2-varSqSyms/2);
level    = sqrt(meanSqSyms-variance);