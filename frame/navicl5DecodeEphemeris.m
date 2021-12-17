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

function [eph, obsCh] = navicl5DecodeEphemeris(obsCh, I_P, prn, ~, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function decodes ephemeris and time of week for all channels for IRNSS L5
% signals.
%
%   Inputs:
%       obsCh               - Observations for one channel
%       I_P                 - Prompt correlator output
%       prn                 - Prn number
%       signalSettings      - Settings for one signal
%       const               - Constants
%   Outputs:
%       eph                 - SV ephemeris
%       obsCh               - Observations for one channel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% initialize
ephemeris = [];

%% Decode ephemerides =====================================================
%=== Convert tracking output to navigation bits =======================

%--- syncronize start of data record with subframe start and copy integer number of symbols samples ---------------
navSymbolSamples = I_P(obsCh.firstSubFrame:end);
endIndex = size(navSymbolSamples, 2);
navSymbolSamples = navSymbolSamples(1:(endIndex - mod(endIndex,20)))'; %because every nav symbol is 20 nav symbol samples long

%--- Group every 20 vales of symbols into columns ------------------------
navSymbolSamples = reshape(navSymbolSamples, 20, (size(navSymbolSamples, 1) / 20));

%--- Sum all samples in the symbol to get the best estimate -------------
navSymbols = sum(navSymbolSamples);
symbols(navSymbols > 0)  = 1;
symbols(navSymbols <= 0) = 0;

%Every subframe is 600 symbols long. Truncate the part-subframe at the
%end, so we are left with integer number of subframes
endIndex = size(symbols, 2);
navSymbols = symbols(1:(endIndex - mod(endIndex,600)));
%Until this point, we have the navigation symbol and frame synchronization
%Now starts the data decoding

signal = 'navicl5';

%Step 1 - Deinterleaving and decoding one subframe at a time
for symNum = 1:600:length(navSymbols)
    %take one subframe = 600 nav symbols at a time and pass to
    %deinterleaver
    deinterleavedSubFrame = navicl5Deinterleaver(navSymbols(symNum:symNum-1+600));
    %now pass this deinterleaved subframe through a FEC decoder
    FECdecodedSubFrame = navicl5Decoder(deinterleavedSubFrame,signal);
    
    %Step 2 - CRC Check - will be done later
    %simple check for correctness of sub frame FEC decoding is to check the
    %tail bits are zeros
    if (isequal(FECdecodedSubFrame(287:292),[0 0 0 0 0 0]) == 0)
        error('Sub frame decoding was unsuccessful!');
    end
    %Step 3 - Extract the ephemeris, almanac and other nav parameters
    %present in the currently decoded subFrame
    
    %--- Convert from decimal to binary -----------------------------------
    % The function navicl5DecodeEphemeris expects input in binary form. In Matlab it is
    % a string array containing only "0" and "1" characters.
    FECdecodedSubFrame = dec2bin(FECdecodedSubFrame);
    FECdecodedSubFrame = FECdecodedSubFrame';
    [ephemeris, TOW] = navicl5DecodeSubframes(FECdecodedSubFrame, ephemeris, const);
    
    %store the TOW only once in the first iteration
    if ~isfield(ephemeris,'tow')
        ephemeris.tow = TOW;
    end
end

eph = ephemeris;

%--- Exclude satellite if it does not have the necessary nav data -----
if (isempty(eph.a_f0) || isempty(eph.C_rc) || isempty(eph.M_0) || isempty(eph.i_0) || isempty(eph.tow) || eph.health == 1)
    disp(['   Ephemeris for NAVIC L5 prn ', int2str(prn),' NOT found.'])
    obsCh.bEphOk = false;
else
    disp(['   Ephemeris for NAVIC L5 prn ', int2str(prn),' found.'])
    obsCh.tow = eph.tow;
    obsCh.bEphOk = true;
end