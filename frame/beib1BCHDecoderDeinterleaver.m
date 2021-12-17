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
function BCH_decoded_deinterleaved_word = beib1BCHDecoderDeinterleaver(NHdecoded_sbfrm, sbfrm_num, word_num)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function BCH decodes the incoming 30-bit word. We assume that the
% sub-frame synchronization and NH decoding has already been performed.
% First we check if the incoming word is word 1 (by checking if the first
% 11 bits are the preamble. If yes, it does not perform anything on the
% first 15 bits. For the next 15 bits, it only decodes the BCH codes.
% For the next 9 words, it first performs deinterleaving and separates two
% 15-bit BCH coded strings, which then it decodes to form two 11-bit
% information strings.
%
% Inputs:
%   NHdecoded_sbfrm     - one word (30 bits) NH decoded but not BCH
%                          decoded/deinterleaved
%   sbfrm_num           - Subframe number
%   word_num            - Word number
%
% Outputs:
%   BCH_decoded_deinterleaved_word - 22-bit BCH decoded and
%                                      deinterleaved data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If we find a preamble in the first 11 bits of the incoming word, treat
% this as word 1. How can we add a check to confirm that this is indeed a preamble and not
% a data sequence coincidence??
if isequal(NHdecoded_sbfrm(1:11),[1 1 1 0 0 0 1 0 0 1 0]) == 1
    % For next 15 bits, perform BCH decoding
    for_BCH_decoding = NHdecoded_sbfrm(16:30);
    BCH_decoded1 = beib1BCHDecoder(for_BCH_decoding, sbfrm_num, word_num);

    % Copy first 15 bits as they are to decoded word. Copy next 11 decoded
    % bits
    BCH_decoded_deinterleaved_word = [NHdecoded_sbfrm(1:15) BCH_decoded1];
else
    % If it is not the word 1, perform deinterleaving....
    deinterleaved1 = NHdecoded_sbfrm(1:2:29);
    deinterleaved2 = NHdecoded_sbfrm(2:2:30);

    % ...then perform BCH decoding
    deinterleaved_BCH_decoded1 = beib1BCHDecoder(deinterleaved1, sbfrm_num, word_num);
    deinterleaved_BCH_decoded2 = beib1BCHDecoder(deinterleaved2, sbfrm_num, word_num);
    BCH_decoded_deinterleaved_word = [deinterleaved_BCH_decoded1 deinterleaved_BCH_decoded2];
end

