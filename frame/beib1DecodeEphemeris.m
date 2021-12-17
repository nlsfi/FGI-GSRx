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
function [eph, obsCh] = beib1DecodeEphemeris(obsCh, I_P, prn, signalSettings, const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function decodes ephemerides and time of frame start from the given bit
% stream. 
%
% Inputs:
%   obsCh               - Observations for one channel
%   I_P                 - Prompt correlator output
%   prn                 - Prn number
%   signalSettings      - Settings for one signal
%   const               - Constants
%
% Outputs:
%   eph                 - SV ephemeris
%   obsCh               - Observations for one channel
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Symbol samples from tracking
navSymbolsSamples = I_P(obsCh.firstSubFrame:obsCh.firstSubFrame + (30000) -1)';

% Separate for GEO satellites (D2)
if(prn > 5)
    decodedBits = navSymbolsSamples; 
    arrayLength = 30000;
    subfLength = 6000;
    nrSubf = 5;
else
    % For D2
    for ii= 1:2:length(navSymbolsSamples)-1
        decodedBits(ceil(ii/2)) = sum(navSymbolsSamples(ii:ii+1));
    end
    arrayLength = 15000;
    subfLength = 300;
    nrSubf = 50;
end

% Extract only the sign
navBitsSamples = sign(decodedBits);

% TBA Function does not check parity!

if length(navBitsSamples)<arrayLength
    error('The data array does not contain enough bits !!!)');
end

eph = [];
ephTemp = [];
alm = [];
subfMask = 0;

for i=1:nrSubf
    curr_sbfrm = navBitsSamples(subfLength*(i-1)+1 : subfLength*(i-1)+subfLength);
    % ndata = curr_sbfrm(1:subfLength);
    
    if(prn > 5)
        demod_data = kron(ones(1,300), signalSettings.secondaryCode);

        % Remove Neumann-Hoffman secondary code from data.
        ndata = curr_sbfrm' .* demod_data; 

        % Convert 20 bits to 1 bit.
        ndata = reshape(ndata, 20, (length(ndata) / 20));
        ndata = sum(ndata, 1);
        ndata = sign(ndata);
    else
        ndata = curr_sbfrm;
    end

    if (sign(sum(ndata(1:11).*signalSettings.preamble))==-1) 
        ndata = -ndata;
    end

    NHdecoded_sbfrm = ndata;
    
    % Convert "-1"/"+1" bits to "0"/"1".
    NHdecoded_sbfrm = (NHdecoded_sbfrm+1)/2;        
    
    wrong_bits = find(NHdecoded_sbfrm==0.5);      
    
    % This check is important for the case of weak signals or signal lost.
    if ~isempty(wrong_bits)
        msg = 'NH decoding failed';
        disp(msg);
        continue; % Goto next loop iteration.     
    end                                         
    
    % NHdecoded_sbfrm here did not originally include the first 11 preamble bits.
    % However, with the addition of the BCH decoder, I had to comment this
    % line and replace it with the following (please also check the changes made in beiDecodeSubframe.m):
    % sbfrm_num = bin2dec(  strcat( dec2bin(decoded_sbfrm(5:7)) )'  );
    sbfrm_num = bin2dec(  strcat( dec2bin(NHdecoded_sbfrm(16:18)) )'  );
    if sbfrm_num > 5 || sbfrm_num < 1
        error('Ephemeris decoding failed!');
    end
    
    
    % Inserting the BCH decoder deinterleaver here
    % NH and BCH decoded (and deinterleaved) subframe is now called
    % decoded_sbfrm. Call the BCH decoder deinterleaver for every word at a
    % time
    decoded_sbfrm_with_preable = zeros(1, 224); %preallocate
    for word_num = 1:10
        decoded_partial_sbfrm = beib1BCHDecoderDeinterleaver(NHdecoded_sbfrm(30*(word_num-1)+1 : 30*(word_num-1)+30), sbfrm_num, word_num);
        if word_num == 1
            decoded_sbfrm_with_preable = decoded_partial_sbfrm;
        else
            decoded_sbfrm_with_preable(22*(word_num-2)+27 : (22*(word_num-2)+27)+21) = decoded_partial_sbfrm;
        end
    end
    
    % Remove preamble
    decoded_sbfrm = decoded_sbfrm_with_preable(12:224);

    if(prn > 5)
        eph.geo = false;
        [eph,alm,subfMask] = beib1DecodeSubframes(sbfrm_num,decoded_sbfrm, eph, alm, subfMask);
        if(bitand(subfMask,7) == 7) % TBA. Check health status from somewhere ?            
            obsCh.tow = bin2dec(  strcat( dec2bin(decoded_sbfrm(8:27)) )'  ) - 24; % - 11*0.020;%%30;
            obsCh.bEphOk = true;
        else
            obsCh.bEphOk = false;
        end
    else
        eph.geo = true;
        [eph,ephTemp,alm,subfMask] = beib1DecodeSubframesD2(sbfrm_num,decoded_sbfrm, eph, ephTemp, alm, subfMask);
        if(bitand(subfMask,1023) == 1023)            
            obsCh.tow = bin2dec(  strcat( dec2bin(decoded_sbfrm(8:27)) )'  ) - 30 + sbfrm_num*0.6; %- 24; % - 11*0.020;%%30;
            obsCh.bEphOk = true;
        else
            obsCh.bEphOk = false;
        end
    end
end

% Output info
if(obsCh.bEphOk == true)
    disp(['   Ephemeris for ', obsCh.signal ,' prn ', ...
        int2str(prn),' found.'])          
else
    disp(['   Ephemeris for ', obsCh.signal ,' prn ', ...
        int2str(prn),' is NOT found.'])  
end
