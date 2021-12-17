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
function [dIono, tec] = neQuickIonoCorrection( towMs, week, userpos, satpos, freq, ionoParam, const)
% [dIono, tec] = neQuickIonoCorrection( towMs, week, userpos, satpos, freq, ionoParam )
%
% Evaluates the NeQuick G ionospheric correction model. It models the
% ionosphere as three layers (E, F1, F2) instead of the thin shell approach of
% the GPS Klobuchar model.
%
% Inputs:
%          towMs      scalar reference time of week in milliseconds
%          week       GPS week number; MUST be corrected for roll-over
%          userpos    user XYZ coordinates
%          satpos     n×3 array of satellite XYZ coordinates
%          freq       1×m vector of carrier frequencies [Hz]
%          ionoParam  structure containing the broadcast NeQuick G parameters
%                     DEFAULT: struct( 'a0', 63.7, 'a1', 0, 'a2', 0 )
%
% Outputs: 
%          dIono      n×m array of ionospheric group delays in units of meters
%          tec        n×1 vector of estimated TEC values in TECU (1e16 el/m²)

% Reference: "Ionospheric Correction Algorithm for Galileo Single Frequency
%            Users", issue 1.2, European Commission, September 2016
% (This reference document is referred to as the "spec" from this point on)

% $Id: neQuickIonoCorrection.m 1270 2017-03-06 14:18:02Z MKJ $

%% Check input parameters and initialize the output array
if ~isscalar( towMs )
    error( 'Expected scalar ToW, %d×%d encountered', size( towMs, 1 ), ...
                                                     size( towMs, 2 ) );
end

if ~isscalar( week )
    error( 'Expected scalar week number, %d×%d encountered', size( week, 1 ), ...
                                                             size( week, 2 ) );
end

[n, temp] = size( satpos );
if temp ~= 3
    error( 'Expected n×3 array of satellite coordinates, %d×%d encountered', ...
           n, temp );
end

if ~isvector( freq )
    error( 'Expected a vector of carrier frequencies, %d×%d encountered', ...
           size( freq, 1 ), size( freq, 2 ) );
end
% Force to row vector
freq = freq(:)';

% If all broadcast ionosphere parameters are equal to zero, 
% one shall use ai0 = 63.7 (see Section 3.1 of the algorithm definition doc)
if ~exist( 'ionoParam', 'var' ) || isempty( ionoParam ) ...
        || (ionoParam.a0 == 0 && ionoParam.a1 == 0 && ionoParam.a2 == 0)
    ionoParam = struct( 'a0', 63.7, 'a1', 0, 'a2', 0 );
%     warning( 'neQuickIonoCorrection:allZeroModel', ...
%              'All-zero broadcast parameters received, defaulting to a0 = %f', ...
%              ionoParam.a0 );
    
end

% Ensure the input coordinates are in XYZ
if norm( userpos ) < 6e6 || any( sqrt( sum( satpos.^2, 2 ) ) < 18e6 )
    warning( 'neQuickIonoCorrection:coordFrame', ...
             'Expecting coordinates in the XYZ frame, inputs look like LLA' );
end

tec = NaN( n, 1 );

%% Transform the coordinates to WGS84 LLA. Note: Altitude in kilometers, not meters!
[posLLA(1), posLLA(2), posLLA(3)] = wgsxyz2lla( const, userpos );
posLLA(3) = posLLA(3) / 1000;
for s = n:-1:1
    [slat, slon, salt] = convXyz2Geod( const, satpos(s, :) );
    satLLA(n, :) = [slat, slon, salt/1000];
end

%% The actual TEC estimation begins here
params.towMs = towMs;
params.week = week;
params.ut = mod( towMs/(3600*1000), 24 );
[~, params.month] = localtime( params.towMs, week, posLLA );
params.modip = modip( posLLA );
params.Az = effectiveIonization( params.modip, ionoParam );
params.AzR = effectiveSunspotNumber( params.Az );
params.posLLA = posLLA;
params.coeff = ionoParam;

% Now evaluate the STEC for each satellite
for s = 1:n
    params.satLLA = satLLA(s, :);
    vertical = false;
    % Initialize geometry structure
    geom = struct();
    geom.P1.LLA = posLLA;
    geom.P2.LLA = params.satLLA;
    geom.Pact.LLA = [geom.P1.LLA(1:2) geom.P2.LLA(3)];
    
    try
        geom = getRayProperties( geom );
        P0.LLA = [NaN NaN max( 0, geom.P1.LLA(3) )];
        P0.R = P0.LLA(3) + R_E();
        P0.S = sqrt( P0.R^2 - geom.ray.LLA(3)^2 );
        geom.Pact.LLA = [geom.P1.LLA(1:2) geom.P2.LLA(3)];
        [geom.sinD, geom.cosD] = solarDeclination( params );
        
        % If the perigee radius is below 0.1 km, use the vertical TEC algorithm        
        if geom.ray.LLA(3) < 0.1
            vertical = true;
            [layers, Nmax] = getEpsteinParameters( params, geom.Pact.LLA, ...
                                                   geom.sinD, geom.cosD );
        else
            layers = [];
            Nmax = -1;
        end
        [tec(s), valid] = integrateTEC( params, geom, P0, Nmax, layers, vertical );
        if ~valid
            warning( 'neQuickIonoCorrection:BeyondTolerance', ...
                     'Integration error larger than tolerance for satellite %d at ToW %f', ...
                     s, towMs/1000 );
        end
    catch mError
        if strcmp( mError.identifier, 'NeQuick:getRayProperties:InvalidRay' )
            tec(s) = NaN;
        else
            % This error is something unexpected -- pass it on
            rethrow( mError );
        end
    end
end

% Evaluate code delay for each carrier frequency
dIono = tec * (40.3 ./ (freq.^2));
tec = tec / 1e16;  % Scale from electrons/m² to TECU

%% Computes the line-of-sight ray properties, the zenith angle of the satellite,
% and the sine and cosine of the azimuth of the satellite as seen from posLLA
function geom = getRayProperties( geom )
% Check if the ray is vertical
if abs( geom.P1.LLA(1) - geom.P2.LLA(1) ) < 1e-5 ...
        && abs( geom.P1.LLA(2)- geom.P2.LLA(2) ) < 1e-5
    geom.P2.LLA(2) = geom.P1.LLA(2);
end

geom.P1.R = geom.P1.LLA(3) + R_E();
geom.P2.R = geom.P2.LLA(3) + R_E();

if abs( geom.P1.LLA(1) - geom.P2.LLA(1) ) < 1e-5 ...
        && abs( geom.P1.LLA(2)- geom.P2.LLA(2) ) < 1e-5
    geom.zeta = 0;
    geom.ray.LLA = [geom.P1.LLA(1:2) 0];        
else
    [geom.ray.LLA, geom.zeta, geom.sinS, geom.cosS] ...
        = slantIntegrationPath( geom.P1.LLA, geom.P2.LLA );
end

if abs( geom.zeta ) > 90 && geom.ray.LLA(3) < R_E()
    error( 'NeQuick:getRayProperties:InvalidRay', ...
           'Invalid ray: zenith angle = %f deg, perigee radius = %f km < Earth radius %f km', ...
           geom.zeta, geom.ray.LLA(3), R_E() );
end

% Integration endpoints, i.e., distances of user and sat from the ray perigee
geom.P1.S = sqrt( geom.P1.R^2 - geom.ray.LLA(3)^2 );
geom.P2.S = sqrt( geom.P2.R^2 - geom.ray.LLA(3)^2 );

%% Compute the Epstein parameters
function [layers, Nmax] = getEpsteinParameters( params, currPos, ...
                                                sinDelta, cosDelta )                                            
currModip = modip( currPos );
Nmax = -1;
lt = localtime( params.towMs, params.week, currPos );
[~, chiEff] = solarZenithAngles( currPos, lt, sinDelta, cosDelta );

[layers.f0E, NmE] = layerE( currPos, params.Az, chiEff, params.month );

[layers.f0F2, NmF2, layers.M3000F2] = layerF2( params.month, params.ut, ...
                                               params.AzR, currModip, currPos );
                                           
[layers.f0F1, NmF1] = layerF1( layers.f0E, layers.f0F2 );                                           

[layers.hmE, layers.hmF1, layers.hmF2] = maximumDensityHeight( layers.f0E, ...
                                           layers.f0F2, layers.M3000F2 );
[layers.B2bot, layers.B1top, layers.B1bot, layers.BEtop, layers.BEbot] ...
           = getThicknessParameters( NmF2, layers.f0F2, layers.hmE, ...
                                     layers.hmF1, layers.hmF2, layers.M3000F2 );
[layers.A1, layers.A2, layers.A3] ...
       = getLayerAmplitudes( NmE, NmF1, NmF2, layers.hmE, layers.hmF1, layers.hmF2, ...
                             layers.BEtop, layers.B1bot, layers.B2bot, ...
                             layers.f0F1 );
k = getShapeParameter( params.month, NmF2, layers.hmF2, layers.B2bot, params.AzR );
layers.H0 = getTopsideThickness( layers.B2bot, k );

%% Calls the integration routine with the proper parameters                         
function [tec, valid] = integrateTEC( params, geom, P0, Nmax, layers, vertical )
if vertical
    hP0 = P0.LLA(3);
    hP1 = geom.P1.LLA(3);
    hP2 = geom.P2.LLA(3);
    % Slant distance of the first integration breakpoint is 1000 km
    S1a = 1000;
    % Height of the second integration breakpoint is 2000 km
    S1b = 2000;
else
    hP0 = P0.S;
    hP1 = geom.P1.S;
    hP2 = geom.P2.S;
    
    % Slant distance of the first integration breakpoint is 1000 km
    S1a = sqrt( (R_E() + 1000)^2 - geom.ray.LLA(3)^2 );
    % Slant distance of the second integration breakpoint is 2000 km
    S1b = sqrt( (R_E() + 2000)^2 - geom.ray.LLA(3)^2 );
end

if geom.P2.LLA(3) <= 1000
    % Satellite altitude below 1000 km; not a likely scenario though
    [tec, valid] = integrateElectronDensity( hP0, hP2, geom, vertical, ...
                                             layers, Nmax );
else
    if geom.P2.LLA(3) <= 2000
        if geom.P1.LLA(3) >= 1000
            % User altitude above 1000 km; accounting for this, too...
            [tec, valid] = integrateElectronDensity( params, hP1, hP2, geom, vertical, ...
                                                     layers, Nmax );
        else
            [tec1, valid1] = integrateElectronDensity( params, hP0, S1a, geom, vertical, ...
                                                       layers, Nmax );
            [tec2, valid2] = integrateElectronDensity( params, S1a, hP2, geom, vertical, ...
                                                       layers, Nmax );
            tec = tec1 + tec2;
            valid = valid1 && valid2;
        end
    else
        if geom.P1.LLA(3) >= 2000
            [tec, valid] = integrateElectronDensity( params, hP1, hP2, geom, vertical, ...
                                                     layers, Nmax );
        else
   
            if geom.P1.LLA(3) >= 1000
                [tec1, valid1] = integrateElectronDensity( params, hP1, S1b, geom, vertical, ...
                                                           layers, Nmax );
                [tec2, valid2] = integrateElectronDensity( params, S1b, hP2, geom, vertical, ...
                                                           layers, Nmax );
                tec = tec1 + tec2;
                valid = valid1 && valid2;
            else
                [tec1, valid1] = integrateElectronDensity( params, hP0, S1a, geom, vertical, ...
                                                           layers, Nmax );
                [tec2, valid2] = integrateElectronDensity( params, S1a, S1b, geom, vertical, ...
                                                           layers, Nmax );
                [tec3, valid3] = integrateElectronDensity( params, S1b, hP2, geom, vertical, ...
                                                           layers, Nmax );
                tec = tec1 + tec2 + tec3;
                valid = valid1 && valid2 && valid3;
            end
        end
    end
end

% Now convert to proper TEC units: we're integrating based on heights in
% kilometers, not meters
tec = 1000 * tec;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Auxiliary Parameters
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Computes the local time and month based on GPS and longitude
function [lt, month] = localtime( towMs, week, posLLA )
lt = mod( mod( towMs/1000, 7*24*3600 ) / 3600 + posLLA(2) / 15, 24 );
gpsEpoch = datenum( '1980-01-06 00:00:00' );
today = addtodate( gpsEpoch, week*7 + floor( towMs / (1000*3600*24) ), 'day' );
month = str2double( datestr( today, 'mm' ) );

%% Computes the Modified Dip Latitude (in units of degrees)
function mu = modip( posLLA )
if abs( posLLA ) >= 90
    warning( 'neQuickIonoCorrection:polarLatitude', ...
             'Requested MODIP for latitude %7.3f', posLLA(1) );
    mu = 90 * sign( posLLA(1) );
    return;
end

% Load the MODIP grid into a persistent variable. Persistent variables are not
% deleted after the function call, so the file on disk is only read once per
% Matlab session (and after 'clear persistent' calls)
persistent stModip
if isempty( stModip )
    % 39×37 array of grid points
    stModip = load( 'modipNeQG_wrapped.txt' );
end

% The specification uses the word 'int' to refer to the floor function
% It is only called for non-negative numbers, so equivalent to fix()
INT = @floor;

% Constants describing the MODIP grid
LNGP = 36;
DLATP = 5;
DLNGP = 10;

lng1 = (posLLA(2) + 180) / DLNGP;
sj = INT( lng1 ) - 2;      % longitude index in grid
dj = lng1 -  INT( lng1 );  % fractional longitude within grid

% Adjust for sign and wrap to grid if necessary
if sj < 0
    sj = sj + LNGP;
end
if sj > (LNGP - 3)
    sj = sj - LNGP;
end

lat1 = (posLLA(1) + 90) / DLATP + 1;
si = INT( lat1 - 1e-6 ) - 2;   % latitude index in grid
di = lat1 - si - 2;            % fractional latitude within grid

% Interpolate across the latitude grid
for k = 4:-1:1
    for j = 4:-1:1
        z1(j) = stModip(si+j+1, sj+k+2);   % Check indexing! 0 vs 1-base!
    end
    z(k) = modip_z_x( z1, di );
end

% Now interpolate the longitude
mu = modip_z_x( z, dj );

%% Third-order interpolation function for MODIP evaluation
function z_x = modip_z_x( z, x )
if abs( 2*x ) < 1e-10
    z_x = z(2);
    return;
end

delta = 2*x - 1;
g1 = z(3) + z(2);
g2 = z(3) - z(2);
g3 = z(4) + z(1);
g4 = (z(4) - z(1)) / 3;

a0 = 9*g1 - g3;
a1 = 9*g2 - g4;
a2 = g3 - g1;
a3 = g4 - g2;

z_x = (a0 + a1*delta + a2*delta^2 + a3*delta^3) / 16;

%% Computes the effective ionization level based on the receiver MODIP 
%  and the broadcast ionosphere parameters
function Az = effectiveIonization( mu, ionoparam )
if ionoparam.a0 == 0 && ionoparam.a1 == 0 && ionoparam.a2 == 0
    Az = 63.7;
else
    Az = ionoparam.a0 + ionoparam.a1 * mu + ionoparam.a2 * mu^2;
end

% Force Az to the interval [0, 400]
if Az < 0
    Az = 0;
elseif Az > 400
    Az = 400;
end

%% Computes the effective sunspot number based on the effective ionization
function AzR = effectiveSunspotNumber( Az )
AzR = sqrt( 167273 + (Az - 63.7) * 1123.6 ) - 408.99;

%% Computes the sine and cosine of the solar declination
function [sinD, cosD] = solarDeclination( params )
dy = 30.5 * params.month - 15;
t = dy + (18 - params.ut) / 24;
am = (0.9856*t - 3.289) * pi/180;
al = am + (1.916 * sin( am ) + 0.020 * sin( 2*am ) + 282.634) * pi/180;
sinD = 0.39782 * sin( al );
cosD = sqrt( 1 - sinD^2 );

%% Computes the solar zenith angles in degrees
function [chi, chiEff] = solarZenithAngles( posLLA, lt, sinD, cosD )
cosX = sind( posLLA(1) ) * sinD + cosd( posLLA(1) ) * cosD * cos( pi/12 * (12-lt) );
chi = atan2d( sqrt( 1 - cosX^2 ), cosX );

chiEff = neqJoin( 90.0 - 0.24*expClip( 20.0 - 0.2*chi ), chi, 12, chi - chi0() );
      
%% Constant: solar zenith angle at night transition = 86.23 deg
function ret = chi0()
ret = 86.23292796211615;  

%% Constant: Earth mean radius = 6371.2 km
function ret = R_E()
ret = 6371.2;
      
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Model Parameters
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% E layer critical frequency [MHz] and maximum density [1e11 m^-3]
function [f0E, NmE] = layerE( posLLA, Az, chiEff, month )

if any( month == [1 2 11 12] )
    seas = -1;
elseif any( month == [3 4 9 10] )
    seas = 0;
elseif any( month == [5 6 7 8] )
    seas = 1;
else
    error( 'Invalid month: %d', month );
end

ee = expClip( 0.3 * posLLA(1) );
seasp = seas * (ee - 1) / (ee + 1);

f0E = sqrt( (1.112 - 0.019*seasp)^2 * sqrt( Az ) * cosd( chiEff )^0.6 + 0.49 );
NmE = 0.124 * f0E^2;

%% F1 layer critical frequency [MHz] and maximum density [1e11 m^-3]
function [f0F1, NmF1] = layerF1( f0E, f0F2 )
% f0F1 is reduced by 15 % if too close to f0F2
f0F1 = neqJoin( 1.4*f0E, 0, 1000.0, f0E-2 );
f0F1 = neqJoin( 0, f0F1, 1000.0, f0E-f0F1 );
f0F1 = neqJoin( f0F1, 0.85*f0F1, 60.0, 0.085*f0F2-f0F1 );

if f0F1 < 1e-6
    f0F1 = 0;
end
NmF1 = 0.124 * f0F1^2; 

%% F2 layer critical frequency, maximum density, and transmission factor
function [f0F2, NmF2, M3000F2] = layerF2( month, ut, AzR, MODIP, posLLA )
% Read the CCIR coefficients for this month from disk (if not already done)
persistent F2 Fm3 XX;
if isempty( XX ) || XX ~= month + 10
    XX = month + 10;
    fname = sprintf( 'ccir%2d.txt', XX );
    fid  = fopen( fname, 'r' );
    if fid == -1
        error( 'Error opening CCIR file ''%s''', fname );
    end
    ccir = fscanf( fid, '%f', 2858 );
    fclose( fid );
    
    % Now pick the 2×76×13 F2 entries and 2×49×9 Fm3 entries
    F2 = NaN( 2, 76, 13 );
    for ii = 0:1
        for jj = 0:75
            for kk = 1:13
                F2(ii+1, jj+1, kk) = ccir(ii*76*13 + jj*13 + kk);
            end
        end
    end
    Fm3 = NaN( 2, 49, 9 );
    for ii = 0:1
        for jj = 0:48
            for kk = 1:9
                Fm3(ii+1, jj+1, kk) = ccir(1976 + ii*49*9 + jj*9 + kk);
            end
        end
    end
end

% Interpolate ITU-R coefficients for AzR
AF2 = NaN( 76, 13 );  % Coefficients for f0F2
for j = 1:76
    for k = 1:13
        AF2(j, k) = F2(1, j, k) * (1 - AzR/100) + F2(2, j, k) * AzR/100;
    end
end

Am3 = NaN( 49, 9 );  % Coefficients for M(3000)F2
for j = 1:49
    for k = 1:9
        Am3(j, k) = Fm3(1, j, k) * (1 - AzR/100) + Fm3(2, j, k) * AzR/100;
    end
end

% Compute Fourier time series for f0F2 and M(3000)F2
CF2 = NaN( 76, 1 );   % Coefficients for f0F2
Cm3 = NaN( 49, 1 );   %                  M(3000)F2

% Time argument
T = (15*ut - 180) * pi/180;
skt = NaN( 6, 1 );
ckt = skt;
skt(1) = sin( T );
ckt(1) = cos(T);
for i = 2:length( skt )
    ckt(i)=ckt(1)*ckt(i-1)-skt(1)*skt(i-1);
    skt(i)=ckt(1)*skt(i-1)+skt(1)*ckt(i-1);
end

for i = 1:76
    CF2(i) = AF2(i, 1);
    for k = 1:6
        CF2(i) = CF2(i) + AF2(i, 2*k) * skt(k) + AF2(i, 2*k+1) * ckt(k);
    end
end

for i = 1:49
    Cm3(i) = Am3(i, 1);
    for k = 1:4
        Cm3(i) = Cm3(i) + Am3(i, 2*k) * skt(k) + Am3(i, 2*k+1) * ckt(k);
    end
end

% Compute F0F2 and M(3000)F2 by Legendre calculation
% First construct vectors of sines and cosines of the coordinates
k = 2:12;
M = [1 sind( MODIP ).^(k-1)];
M(abs( M ) < 1e-30) = 0;  % Force small values to zero
n = 2:9;
P = [NaN cosd( posLLA(1) ).^(n-1)];
S = [NaN sind( (n-1) * posLLA(2) )];
C = [NaN cosd( (n-1) * posLLA(2) )];

f0F2n = zeros( 9, 1 );
f0F2n(1) = M * CF2(1:12);
Q = [12 12 9 5 2 1 1 1 1];   % Legendre grades
K = NaN( 9, 1 );
K(1) = -Q(1);
for n = 2:9
    K(n) = K(n-1) + 2*Q(n-1);
end

for n = 2:9
    for k = 1:Q(n)
        f0F2n(n) = f0F2n(n) + (CF2(K(n)+2*k-1)*C(n) + CF2(K(n)+2*k)*S(n)) * M(k) * P(n);
    end
end
f0F2 = sum( f0F2n );

M3000F2n = zeros( 7, 1 );
M3000F2n(1) = M(1:7) * Cm3(1:7);
R = [7 8 6 3 2 1 1];  % Legendre grades
H = NaN( 7, 1 );
H(1) = -R(1);
for n = 2:7
    H(n) = H(n-1) + 2*R(n-1);
end

for n = 2:7
    for k = 1:R(n)
        M3000F2n(n) = M3000F2n(n) + (Cm3(H(n) + 2*k-1)*C(n) + Cm3(H(n)+2*k)*S(n))*M(k)*P(n);
    end
end
M3000F2 = sum( M3000F2n );
NmF2 = 0.124 * f0F2^2;


%% Compute the maximum density heights [km] for the E, F1, and F2 layers
function [hmE, hmF1, hmF2] = maximumDensityHeight( f0E, f0F2, M3000F2 )
hmE = 120;   % constant

% hmF2
if f0E < 1e-30
    deltaM = -0.012;
else    
    rho = ((f0F2/f0E) * expClip( 20*(f0F2/f0E -1.75)) + 1.75) ...
          / (expClip(20*(f0F2/f0E -1.75)) + 1);    
    deltaM = 0.253 / (rho - 1.215) - 0.012;
end
hmF2 = (1490 * M3000F2 * sqrt( (0.0196*M3000F2^2 + 1) / (1.2967*M3000F2^2 - 1) )) ...
       / (M3000F2 + deltaM) - 176;

% hmF1
hmF1 = (hmF2 + hmE) / 2;

%% Compute the thickness parameters in units of kilometers
function [B2bot, B1top, B1bot, BEtop, BEbot] ...
           = getThicknessParameters( NmF2, f0F2, hmE, hmF1, hmF2, M3000F2 )
B2bot = 0.385 * NmF2 ... % Note: no expClip
        / (0.01 * exp( -3.467 + 0.857*log( f0F2^2 ) + 2.02 * log( M3000F2 ))); 
B1top = 0.3 * (hmF2 - hmF1);
B1bot = 0.5 * (hmF1 - hmE);
BEtop = max( B1bot, 7 );
BEbot = 5;  % constant

%% Compute the F2, F1, and E layer amplitudes [1e11 m^-3]
function [A1, A2, A3] = getLayerAmplitudes( NmE, NmF1, NmF2, hmE, hmF1, ...
                                            hmF2, BEtop, B1bot, B2bot, f0F1 )
A1 = 4 * NmF2;
A2 = 4 * NmF1;
A3 = 4 * NmE;

if f0F1 < 0.5
    A2 = 0;
    A3 = 4.0 * (NmE - epstein( A1, hmF2, B2bot, hmE ));
else
    for iter = 1:5
        A2 = 4 * (NmF1 - epstein( A1, hmF2, B2bot, hmF1 ) ...
                       - epstein( A3, hmE, BEtop, hmF1 ));
        A2 = neqJoin( A2, 0.8 * NmF1, 1, A2-0.8*NmF1 );
        A3 = 4 * (NmE - epstein( A2, hmF1, B1bot, hmE ) ...
                      - epstein( A1, hmF2, B2bot, hmE ));
    end
end
A3 = neqJoin( A3, 0.05, 60.0, A3-0.005 );  % spec states 0.05 for param 2, ref has 0.005


%% Compute the shape parameter
function k = getShapeParameter( month, NmF2, hmF2, B2bot, AzR )
if any( month == [4 5 6 7 8 9] )
    ka = 6.705 - 0.014*AzR - 0.008*hmF2;
elseif any( month == [1 2 3 10 11 12] )
    ka = -7.77 + 0.097*(hmF2/B2bot)^2 + 0.153*NmF2;
else
    error( 'Invalid month %d -- how did it survive this far?', month );
end

k = neqJoin( ka, 2, 1, ka-2.0 );
k = neqJoin( 8, k, 1, k-8.0 );

%% Compute the topside thickness in kilometers
function H0 = getTopsideThickness( B2bot, k )
Ha = k * B2bot;
x = (Ha - 150) / 100;
v = (0.041163*x - 0.183981) * x + 1.424472;

H0 = Ha / v;

%% Compute the (vertical) electron density [m^-3] at height h [km]
function N = verticalElectronDensity( h, A1, A2, A3, hmE, hmF1, hmF2, H0, ...
                                      B2bot, B1top, B1bot, BEtop, BEbot, Nmax )
if h <= hmF2
    % Evaluate the bottomside electron density
    BF2 = B2bot;
    if h > hmE
        BE = BEtop;
    else
        BE = BEbot;
    end
    
    if h > hmF1
        BF1 = B1top;
    else
        BF1 = B1bot;
    end
    
    h100 = max( h, 100 );
    % Exponential arguments for each layer
    alpha(1) = (h100 - hmF2) / BF2;
    alpha(2) = (h100 - hmF1)/BF1 * exp( 10 / (1 + abs( h100 - hmF2 )) );
    alpha(3) = (h100 - hmE)/BE   * exp( 10 / (1 + abs( h100 - hmF2 )) );
    
    A = [A1 A2 A3];
    for i = 3:-1:1
        if abs( alpha(i) ) > 25
            s(i) = 0;
        else
            s(i) = A(i) * exp( alpha(i) ) / (1 + exp( alpha(i)))^2;
        end
    end
    
    if h >= 100
        N = sum( s ) * 1e11;
        return;
    end
    
    % For lower heights, include corrective and Chapman terms
    if abs( alpha(3) ) > 25
        ds(3) = 0;
    else
        ds(3) = 1/BE * (1 - exp( alpha(3) )) / (1 + exp( alpha(3) ));
    end
    if abs( alpha(1) ) > 25
        ds(1) = 0;
    else
        ds(1) = 1/BF2 * (1 - exp( alpha(1) )) / (1 + exp( alpha(1) ));
    end
    if abs( alpha(2) ) > 25
        ds(2) = 0;
    else
        ds(2) = 1/BF1 * (1 - exp( alpha(2) )) / (1 + exp( alpha(2) ));
    end
    
    BC = 1 - 10 * dot( s, ds ) / sum( s );
    z = (h - 100) / 10;
    
    N = sum( s ) * expClip( 1 - BC*z - expClip( -z ) ) * 1e11;
    
else 
    % Topside electron density
    g = 0.125;
    r = 100;
    deltah = h - hmF2;
    z = deltah / (H0 * (1 + r*g*deltah / (r*H0 + g*deltah) ));
    ea = expClip( z );
    
    if ea > 1e11
        ep = 4 / ea;
    else
        ep = 4 * ea / (1 + ea)^2;
    end
    
    if Nmax < 0
        % evaluate Nmax at crossover point hmF2
        Nmax = verticalElectronDensity( hmF2, A1, A2, A3, hmE, hmF1, hmF2, H0, ...
                                        B2bot, B1top, B1bot, BEtop, BEbot, Nmax );
    end
    N = Nmax * ep;
end
   

function [r_p, phi_p, lam_p, zeta] = getRayPerigee( posLLA, satLLA )
% Compute the zenith angle zeta [deg]
cosD = sind( posLLA(1) ) * sind( satLLA(1) ) ...
       + cosd( posLLA(1) ) * cosd( satLLA(1) ) * cosd( satLLA(2) - posLLA(2) );
sinD = sqrt( 1 - cosD^2 );
zeta = atan2d( sinD, cosD - (posLLA(3) + R_E()) / (satLLA(3) + R_E()) );

% Ray perigee radius [km]
r_p = (posLLA(3) + R_E()) * sind( zeta );

% Ray perigee latitude and longitude [deg]
if abs( abs( posLLA(1) ) - 90 ) < 1e-10
    phi_p = zeta * sign( posLLA(1) );
    lam_p = satLLA(2) + (zeta >= 0) * 90;
else
    % Latitude
    sinS = (sind( satLLA(2) - posLLA(2) ) * cosd( satLLA(1) )) / sinD;
    cosS = (sind( satLLA(1) ) - cosD * sind( posLLA(1) )) / (sinD * cosd( posLLA(1) ));
    delta_p = 90 - zeta;
    sinPp = sind( posLLA(1) ) * cosd( delta_p ) ...
            - cosd( posLLA(1) ) * sind( delta_p ) * cosS;
    cosPp = sqrt( 1 - sinPp^2 );
    phi_p = atan2d( sinPp, cosPp );
    
    % Longitude
    sinDlam = -sinS * sind( delta_p ) / cosPp;
    cosDlam = (cosd( delta_p ) - sind( posLLA(1) ) * sinPp) ...
              / (cosd( posLLA(1) ) * cosPp);
    lam_p = atan2d( sinDlam, cosDlam ) + posLLA(2);
end

% Computes the ray perigee coordinates, the sine and cosine of the satellite
% azimuth as seen from the user, and the distances of the user and the
% satellite from the ray perigee
function [perLLA, zeta, sinSp, cosSp] = slantIntegrationPath( posLLA, satLLA )
[r_p, phi_p, lam_p, zeta] = getRayPerigee( posLLA, satLLA );
perLLA = [phi_p lam_p r_p];

% Great circle angle [deg] and sine and cosine of satellite azimuth at perigee
if abs( abs( phi_p ) - 90 ) < 1e-10
    sinSp = 0;
    cosSp = -sign( phi_p );
else
    % v3:
    cosPsi = sind( perLLA(1) ) * sind( satLLA(1) ) ...
             + cosd( perLLA(1) ) * cosd( satLLA(1) ) * cosd( satLLA(2) - lam_p );
    sinPsi = sqrt( 1 - cosPsi^2 );

    sinSp = cosd( satLLA(1) ) * sind( satLLA(2) - lam_p ) ...
             / sinPsi;
    cosSp = (sind( satLLA(1) ) - sind( perLLA(1) ) * cosPsi) ...
             / (cosd( perLLA(1) ) * sinPsi);
% v2:  
%     cosPsi = sind( posLLA(1) ) * sind( satLLA(1) ) ...
%              + cosd( posLLA(1) ) * cosd( satLLA(1) ) * cosd( satLLA(2) - lam_p );
%     sinPsi = sqrt( 1 - cosPsi^2 );
%     sinSp = cosd( satLLA(1) ) * sind( satLLA(2) - lam_p ) ...
%              / sinPsi;
%     cosSp = (sind( satLLA(1) ) - sind( posLLA(1) ) * cosPsi) ...
%              / (cosd( posLLA(1) ) * sinPsi);         
end

%% Coordinates along the integration path at distance s
function pLLA = pathCoordinates( P1LLA, perLLA, sinSp, cosSp, s )
pLLA = [NaN NaN NaN];
pLLA(3) = sqrt( s^2 + perLLA(3)^2 ) - R_E();

% Great circle parameters
tanDs = s / perLLA(3);
cosDs = 1 / sqrt( 1 + tanDs^2 );
sinDs = tanDs * cosDs;

% Latitude
sinPhis = sind( perLLA(1) ) * cosDs + cosd( perLLA(1) ) * sinDs * cosSp;
% sinPhis = sind( P1LLA(1) ) * cosDs + cosd( P1LLA(1) ) * sinDs * cosSp;
cosPhis = sqrt( 1 - sinPhis^2 );
pLLA(1) = atan2d( sinPhis, cosPhis );

% Longitude
sinDlam = sinDs * sinSp * cosd( perLLA(1) );   % v3
% sinDlam = sinDs * sinSp * cosd( P1LLA(1) );  % v2
cosDlam = cosDs - sind( perLLA(1) ) * sinPhis; % v3
% cosDlam = cosDs - sind( P1LLA(1) ) * sinPhis; % v2
pLLA(2) = atan2d( sinDlam, cosDlam ) + perLLA(2);

%% Epstein function. Vectorized for possible future convenience.
function out = epstein( x, y, z, w )
% x is peak amplitude, y is peak height, z is thickness around peak, and
% w is the height dependent variable
out = (x .* expClip( (w-y)./z )) ./ (1 + expClip( (w - y)./z ) ).^2;

%% Integrates the electron density to TEC
% Also returns a Boolean parameter to indicate if the result is within
% tolerance (inTol == true implies solution ok)
function [tec, inTol] = integrateElectronDensity( params, H1, H2, geom, vertical, ...
                                                  layers, Nmax, recursionLevel )
% Gauss--Kronrod G_7-K_15 adaptive quadrature
% Performs a 7-point Gauss integration and 15-point Kronrod integration,
% then investigates the difference between these to check if the integration
% interval should be split to two recursive calls

if H2 < 1000
    tolerance = 0.001;  % Default tolerance value for altitudes below 1000 km
else
    tolerance = 0.01;
end

% Define a default value for the recursion level
if ~exist( 'recursionLevel', 'var' )
    recursionLevel = 0;
end

% Define the constant integration parameters
% Not quite convinced that this amount of decimals is necessary, but let's
% stick to the specification...

% 15 Kronrod sample point weights
wi = [0.022935322010529224963732008058970
      0.063092092629978553290700663189204
      0.104790010322250183839876322541518
      0.140653259715525918745189590510238
      0.169004726639267902826583426598550
      0.190350578064785409913256402421014
      0.204432940075298892414161999234649
      0.209482141084727828012999174891714
      0.204432940075298892414161999234649
      0.190350578064785409913256402421014
      0.169004726639267902826583426598550
      0.140653259715525918745189590510238
      0.104790010322250183839876322541518
      0.063092092629978553290700663189204
      0.022935322010529224963732008058970];
  
% 7 Gauss sample point weights
wig = [0.129484966168869693270611432679082
       0.279705391489276667901467771423780
       0.381830050505118944950369775488975
       0.417959183673469387755102040816327
       0.381830050505118944950369775488975
       0.279705391489276667901467771423780
       0.129484966168869693270611432679082];
   
% Sample points within interval [-1, 1]; will be scaled to [H1, H2]
% Kronrod will use all of these, Gauss only uses points 2:2:14
xi = [-0.991455371120812639206854697526329
      -0.949107912342758524526189684047851
      -0.864864423359769072789712788640926
      -0.741531185599394439863864773280788
      -0.586087235467691130294144838258730
      -0.405845151377397166906606412076961
      -0.207784955007898467600689403773245
       0
       0.207784955007898467600689403773245
       0.405845151377397166906606412076961
       0.586087235467691130294144838258730
       0.741531185599394439863864773280788
       0.864864423359769072789712788640926
       0.949107912342758524526189684047851
       0.991455371120812639206854697526329];
   
% Compute half difference and midpoint for scaling the sampling points
h2 = (H2 - H1) / 2;
hh = (H2 + H1) / 2;

% Initialize iteration variables
intk = 0;
intg = 0;
Gind = 1;

for i = 1:15
    x = h2 * xi(i) + hh;
    if vertical
        % For vertical rays (i.e., satellite at zenith), the same ionosphere
        % model is valid throughout the integration. This saves some
        % computational effort
        y = verticalElectronDensity( x, layers.A1, layers.A2, layers.A3, ...
                                     layers.hmE, layers.hmF1, layers.hmF2, ...
                                     layers.H0, layers.B2bot, layers.B1top, ...
                                     layers.B1bot, layers.BEtop, ...
                                     layers.BEbot, Nmax );
    else
        % For slanted rays, the Epstein parameters must be re-evaluated at each
        % integration point.
        [y, geom, layers, Nmax] = slantElectronDensity( x, params, geom );
    end
    
    % Accumulate the Kronrod total
    intk = intk + y * wi(i);
    
    % Note: spec indexes i = 0...14, we have i = 1...15, so the remainder
    % criterion has to be inverted
    if ~mod( i, 2 )  
        % Every other point is a G7 point
        intg = intg + y * wig(Gind);
        Gind = Gind + 1;
    end
end

% Scale the integration results from [-1, 1] to the integration interval
intk = intk * h2;
intg = intg * h2;

% Check the tolerance
if abs( (intk - intg) / intk ) <= tolerance || abs( intk - intg ) <= tolerance
    inTol = true;
    tec = intk;    
elseif recursionLevel == 50  % NOTE: magic number! Seems to be a suitable value.
    % Exceeding tolerance but max recursion level reached, cannot refine anymore
    inTol = false;
    tec = intk;    
else
    % Exceeding tolerance, recursive call
    [tec1, inTol1] = integrateElectronDensity( params, H1,      H1 + h2, geom, ...
                                vertical, layers, Nmax, recursionLevel + 1 );
    [tec2, inTol2] = integrateElectronDensity( params, H1 + h2, H2,      geom, ...
                                vertical, layers, Nmax, recursionLevel + 1 );
    tec = tec1 + tec2;
    inTol = inTol1 && inTol2;
end

%% Computes the Epstein parameters and evaluates the associated electron density
function [N, geom, layers, Nmax] = slantElectronDensity( s, params, geom )
geom.Pact.LLA = pathCoordinates( geom.P1.LLA, geom.ray.LLA, geom.sinS, geom.cosS, s );
[layers, Nmax] = getEpsteinParameters( params, geom.Pact.LLA, ...
                                                   geom.sinD, geom.cosD );
N = verticalElectronDensity( geom.Pact.LLA(3), layers.A1, layers.A2, layers.A3, ...
                                     layers.hmE, layers.hmF1, layers.hmF2, ...
                                     layers.H0, layers.B2bot, layers.B1top, ...
                                     layers.B1bot, layers.BEtop, layers.BEbot, Nmax );

%% Clipped exponential function
function out = expClip( in )
if in > 80
    out = 5.5406e34;
elseif in < -80
    out = 1.8049e-35;
else
    out = exp( in );
end

%% Smooth joining of two functions at origin (continuous in first derivative)
function out = neqJoin( f1, f2, alpha, x )
ee = expClip( alpha * x );
out = (f1 * ee + f2) / (ee + 1);