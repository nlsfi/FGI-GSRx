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
function v = reallyFastLDPCdecoder(H,r,I,var)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function decodes Low-density-parity-check code bit sequences
% The algorithm for this uses belief propagation and is based on Johannesson,
% R., & Zigaangirov, K. S. (2015). "Fundamentals of convolutional coding:
% Algorithm BPDMC" John Wiley & Sons, Incorporated. p. 535.
%
%
% Inputs:
%   H               - LDPC matrix
%   r               - Encoded bit sequence with possbile errors
%   I               - Number of maximum iterations in the algorithm
%   var             - Estimate for the symbol variance
%
% Outputs:
%   v               - Decoded bit sequence
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NOTE: BPDMC{number} marks the sections of the algorithm as described in the Johannesson's & Zigaangirov's book

% Intialize sparce parity check matrix and 
H = sparse(logical(H));
[rowIdx,colIdx] = find(H);
[rowIdx2,colIdx2] = find(H');

% LDPC matrix dimensions
[L,N] = size(H);

% Initialize log-likelihood ratios based on symbol variance
zn0 = -2*r./var;                                            % BPDMC1

% Make decisions on symbols and return immediatly if zero BP iterations is given as a input.
if I == 0
    v = -(sign(zn0)-1)/2;
    return
end

znl = H'.*zn0;                                              % BPDMC2

c = zeros(nnz(H),1);
e = zeros(nnz(H),1);
zni = zeros(N,1);

% I-1 identical iterations
for i = 1 : (I-1)

    j = 1;                                                  % BPDMC3
    a = tanh(znl/2);
    for l = 1:L
        values = nonzeros(a(:,l));
        nb = length(values);
        c(j:j+nb-1) = prod(values)./values;
        j = j + nb;
    end
    d = log((1 + c) ./ (1 - c));

    % Avoid Inf - Inf = NaN situations, by equating infinities to some high value
    filt = isinf(d);
    d(filt) = 100*sign(d(filt));

    yln = sparse(colIdx2,rowIdx2,d);

    j = 1;                                                  % BPDMC4
    for n = 1:N
        values = nonzeros(yln(:,n));
        ne = length(values);
        zni(n) = zn0(n) + sum(values);
        e(j:j+ne-1) = zni(n) - values;
        j = j + ne;
    end

    % Check if the subframe passes the LDPC matrix
    v = -(sign(zni)-1)/2;
    if ~any(mod(H*v,2))
        return
    end

    znl = sparse(colIdx,rowIdx,e);
end

j = 1;                                                      % BPDMC5
a = tanh(znl/2);
for l = 1:L
    values = nonzeros(a(:,l));
    nb = length(values);
    c(j:j+nb-1) = prod(values)./values;
    j = j + nb;
end
d = log((1 + c) ./ (1 - c));

% Avoid Inf - Inf = NaN situations, by equating infinities to some high value
filt = isinf(d);
d(filt) = 100*sign(d(filt));

yln = sparse(colIdx2,rowIdx2,d);

for n = 1:N                                                 % BPDMC6
    values = nonzeros(yln(:,n));
    zni(n) = zn0(n) + sum(values);
end

v = -(sign(zni)-1)/2;                                       % BPDMC7