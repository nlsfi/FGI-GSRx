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
function [spectra,freq] = fftSpec(x,seg_len,overlap,Nfft,Fs,range)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function generates the psd of a given input signal
%
%  Inputs: 
%       x - Input data (time series) 
%       seg_len - length of data that should be used
%       overlap - TBD
%       Nfft - Number of points for FFT
%       Fs - Sampling frequency
%       range - 0 if one sided and 1 if two sided spectrum
%
%   Output:
%       spectra - Spectrum
%       freq - Frequency vector for data
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% TBA Rename all variables

% Make sure that data is always in column vector
if ( size(x,1)==1 )
    x=x(:);
end

% Generate a Hamming window
xx = seg_len - 1;
window = 0.54 - 0.46 * cos( (2*pi/xx)*[0:xx].' );

% Set default overlap as number of samples
overlap = fix(seg_len * overlap / 100 );

% Minimum FFT length is seg_len
Nfft = max( Nfft, seg_len );

% Mean square of window is required for normalising PSD amplitude.
win_meansq = (window.' * window) / seg_len;

% Calculate and accumulate periodograms
% xx is padded data segments
% Pxx is periodogram sums
xx = zeros(Nfft,1);
Pxx = xx;

% Calulate and add FFT's
n_ffts = 0;
x_len = length(x);
for start_seg = [1:seg_len-overlap:x_len-seg_len+1]
    end_seg = start_seg+seg_len-1;

    xx(1:seg_len) = window .* x(start_seg:end_seg);
    fft_x = fft(xx);

    % Force Pxx to be real; pgram = periodogram
    pgram = real(fft_x .* conj(fft_x));
    Pxx = Pxx + pgram;

    % Sum of squared periodograms is required for confidence interval
    n_ffts = n_ffts +1;
end

% Check if we have single or double sided spectrogram
if ( range == 0 )
    if ( ~ rem(Nfft,2) )    % One-sided, Nfft is even
        psd_len = Nfft/2+1;
        Pxx = Pxx(1:psd_len) + [0; Pxx(Nfft:-1:psd_len+1); 0];
    else                    % One-sided, Nfft is odd
        psd_len = (Nfft+1)/2;
        Pxx = Pxx(1:psd_len) + [0; Pxx(Nfft:-1:psd_len+1)];
    end
else % Two-sided
    psd_len = Nfft;
end

% Generate output variables
spectra    = zeros(psd_len,1);
scale = n_ffts * seg_len * Fs * win_meansq;
spectra(:,1) = Pxx / scale;

freq = [0:psd_len-1].' * ( Fs / Nfft );



