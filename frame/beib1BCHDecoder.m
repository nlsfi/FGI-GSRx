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
function BCH_decoded = beib1BCHDecoder(for_BCH_decoding, sbfrm_num, word_num)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes input of 15 BCH encoded bits and decodes them into 11
% bits. It also performs 1-bit error correction (if required).
%
% Inputs:
%   for_BCH_decoding    - 15 bit navigation data to be BCH decoded
%   sbfrm_num           - Subframe number
%   word_num            - Word number
%
% Outputs:
%   BCH_decoded         - 11 bit BCH decoded navigation data with parity
%                           bits removed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Initialize the 4 shift registers to zeros
D0 = 0;
D1 = 0;
D2 = 0;
D3 = 0;
% Perform the BCH decoding algorithm (COMPASS ICD page 14) 15 times
% to form the 4 ROM bits
for bit_num = 1:1:15
    D3_old = D3;
    D3 = D2;
    D2 = D1;
    D1 = xor(D0,D3_old);
    D0 = xor(D3_old, for_BCH_decoding(bit_num));
end

% Now we have the 4 bit ROM. We use it to select the 15 bits for error
% correction as given in Table 5-2 of COMPASS ICD page 14
ROM = [D3 D2 D1 D0];
if isequal(ROM,[0 0 0 0]) == 1
    error_correction = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
elseif isequal(ROM,[0 0 0 1]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 1';
    disp(msg);
    error_correction = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 1];
elseif isequal(ROM,[0 0 1 0]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 2';
    disp(msg);
    error_correction = [0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
elseif isequal(ROM,[0 0 1 1]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 5';
    disp(msg);
    error_correction = [0 0 0 0 0 0 0 0 0 0 1 0 0 0 0];
elseif isequal(ROM,[0 1 0 0]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 3';
    disp(msg);
    error_correction = [0 0 0 0 0 0 0 0 0 0 0 0 1 0 0];
elseif isequal(ROM,[0 1 0 1]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 9';
    disp(msg);
    error_correction = [0 0 0 0 0 0 1 0 0 0 0 0 0 0 0];
elseif isequal(ROM,[0 1 1 0]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 6';
    disp(msg);
    error_correction = [0 0 0 0 0 0 0 0 0 1 0 0 0 0 0];
elseif isequal(ROM,[0 1 1 1]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 11';
    disp(msg);
    error_correction = [0 0 0 0 1 0 0 0 0 0 0 0 0 0 0];
elseif isequal(ROM,[1 0 0 0]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 4';
    disp(msg);
    error_correction = [0 0 0 0 0 0 0 0 0 0 0 1 0 0 0];
elseif isequal(ROM,[1 0 0 1]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 15';
    disp(msg);
    error_correction = [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0];
elseif isequal(ROM,[1 0 1 0]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 10';
    disp(msg);
    error_correction = [0 0 0 0 0 1 0 0 0 0 0 0 0 0 0];
elseif isequal(ROM,[1 0 1 1]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 8';
    disp(msg);
    error_correction = [0 0 0 0 0 0 0 1 0 0 0 0 0 0 0];
elseif isequal(ROM,[1 1 0 0]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 7';
    disp(msg);
    error_correction = [0 0 0 0 0 0 0 0 1 0 0 0 0 0 0];
elseif isequal(ROM,[1 1 0 1]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 14';
    disp(msg);
    error_correction = [0 1 0 0 0 0 0 0 0 0 0 0 0 0 0];
elseif isequal(ROM,[1 1 1 0]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 12';
    disp(msg);
    error_correction = [0 0 0 1 0 0 0 0 0 0 0 0 0 0 0];
elseif isequal(ROM,[1 1 1 1]) == 1
    msg = '*************************';
    disp(msg);
    sbfrm_num
    word_num
    msg = 'Bit Error in position 13';
    disp(msg);
    error_correction = [0 0 1 0 0 0 0 0 0 0 0 0 0 0 0];
end

% Compute the 15 bit error corrected intermediate result as an modulo-2
% between the incoming string and error correction string generated above
intermediate = xor(for_BCH_decoding, error_correction);

% Truncate the last 4 parity bits to reveal the 11 bit information
BCH_decoded = intermediate(1:11);
end