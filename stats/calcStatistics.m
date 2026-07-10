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
function x=calcStatistics(nav,true,navSolPeriod,const)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function for calculating various statistical values 
%
% Input: 
%       nav - navSolutions strucuture from GSR receiver
%       true - true vector [lat lon, alt] 
%       navSolPeriod  - Navigation solution interval
%       solution  - Type of solution (lse of kalman)
% Output: 
%       x        - Structure with various calculated statistical data
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Note that this function uses only lat, lon and height as input and calculates
% all other coordinate transformations itself.

ind = 1;

% Get data to temporary structures

for i=1:length(nav)
    if (nav{i}.Pos.bValid==1)    
        x.VX(ind) =nav{i}.Vel.xyz(1);        
        x.VY(ind) =nav{i}.Vel.xyz(2);        
        x.VZ(ind) =nav{i}.Vel.xyz(3);
        x.X(ind) =nav{i}.Pos.xyz(1);        
        x.Y(ind) =nav{i}.Pos.xyz(2);        
        x.Z(ind) =nav{i}.Pos.xyz(3);        
        x.dt(ind) =nav{i}.Pos.dt(1); % Bias (code)        
        x.df(ind) =nav{i}.Vel.df(1); % Drift (dopplers)        
        x.res(ind,1:12) = 0;        
        x.res(ind,1:length(nav{i}.Pos.rangeResid)) =nav{i}.Pos.rangeResid;
        x.latitude(ind) =nav{i}.Pos.LLA(1);
        x.longitude(ind) =nav{i}.Pos.LLA(2);        
        x.height(ind) =nav{i}.Pos.LLA(3);        
        dop(ind,:) =nav{i}.Pos.dop;            
        fom(ind) =nav{i}.Pos.fom;          
        nSat(ind)=sum(nav{i}.Pos.nrSats);
        ind = ind +1;        
    end    
end
% Set true position
x.trueLat=true(1);
x.trueLong=true(2);
x.trueHeight=true(3);

% Calculate true X,Y,Z
xyz = wgslla2xyz(const,x.trueLat, x.trueLong, x.trueHeight);
x.truex = xyz(1);
x.truey = xyz(2);
x.truez = xyz(3);

% Normalise to 1 Hz
smoothingInterval = 1000/navSolPeriod;

j=1;
for i=1:smoothingInterval:length(nav)-smoothingInterval
    X(j) =mean(x.X(i:i+smoothingInterval-1)); 
    Y(j) =mean(x.Y(i:i+smoothingInterval-1)); 
    Z(j) =mean(x.Z(i:i+smoothingInterval-1));     
    latitude(j)=mean(x.latitude(i:i+smoothingInterval-1));
    longitude(j)=mean(x.longitude(i:i+smoothingInterval-1));
    height(j)=mean(x.height(i:i+smoothingInterval-1));
    noOfUsedSat(j) =mean(nSat(i:i+smoothingInterval-1));
    j=j+1;
end
clear x.X; clear x.Y; clear x.Z; clear x.latitude; clear x.longitude; clear x.height;
x.X = X;
x.Y = Y;
x.Z = Z;
x.latitude = latitude;
x.longitude = longitude;
x.height = height;

% Mean position in x y z coordinates.
x.meanx=mean(x.X);
x.meany=mean(x.Y);
x.meanz=mean(x.Z);

% Select reference to either mean position or true position
x.xr=x.truex;
x.yr=x.truey;
x.zr=x.truez;

% Deviation from reference position
x.dx = x.X-x.xr;
x.dy = x.Y-x.yr;
x.dz = x.Z-x.zr;

%Compute topomatrix
slat = sin(x.latitude(1)/360*2*3.14);
clat = cos(x.latitude(1)/360*2*3.14);
slon = sin(x.longitude(1)/360*2*3.14);
clon = cos(x.longitude(1)/360*2*3.14);

x.topo(1,1) = -slat*clon;
x.topo(1,2) = -slat*slon;
x.topo(1,3) = clat;
x.topo(2,1) = -slon;
x.topo(2,2) = clon;
x.topo(2,3) = 0.0;
x.topo(3,1) = clat*clon;
x.topo(3,2) = clat*slon;
x.topo(3,3) = slat;

% Compute east north up components
x.sn	= (x.topo(1,1)*(x.X-x.xr) + x.topo(1,2)*(x.Y-x.yr) + x.topo(1,3)*(x.Z-x.zr));
x.se	= (x.topo(2,1)*(x.X-x.xr) + x.topo(2,2)*(x.Y-x.yr) + x.topo(2,3)*(x.Z-x.zr));
x.su	= (x.topo(3,1)*(x.X-x.xr) + x.topo(3,2)*(x.Y-x.yr) + x.topo(3,3)*(x.Z-x.zr));

% Compute speed (horisontal) and velocity (3D)
x.vel_n = (x.topo(1,1)*(x.VX) + x.topo(1,2)*(x.VY) + x.topo(1,3)*(x.VZ));
x.vel_e = (x.topo(2,1)*(x.VX) + x.topo(2,2)*(x.VY) + x.topo(2,3)*(x.VZ));
x.vel_u = (x.topo(3,1)*(x.VX) + x.topo(3,2)*(x.VY) + x.topo(3,3)*(x.VZ));

% Compute east north up components for reference position
x.truesn	= (x.topo(1,1)*(x.truex-x.xr) + x.topo(1,2)*(x.truey-x.yr) + x.topo(1,3)*(x.truez-x.zr));
x.truese	= (x.topo(2,1)*(x.truex-x.xr) + x.topo(2,2)*(x.truey-x.yr) + x.topo(2,3)*(x.truez-x.zr));
x.truesu	= (x.topo(3,1)*(x.truex-x.xr) + x.topo(3,2)*(x.truey-x.yr) + x.topo(3,3)*(x.truez-x.zr));

% Compute east north up components for mean position
x.meansn	= (x.topo(1,1)*(x.meanx-x.xr) + x.topo(1,2)*(x.meany-x.yr) + x.topo(1,3)*(x.meanz-x.zr));
x.meanse	= (x.topo(2,1)*(x.meanx-x.xr) + x.topo(2,2)*(x.meany-x.yr) + x.topo(2,3)*(x.meanz-x.zr));
x.meansu	= (x.topo(3,1)*(x.meanx-x.xr) + x.topo(3,2)*(x.meany-x.yr) + x.topo(3,3)*(x.meanz-x.zr));

% Horisontal deviation
x.dhor = sqrt(x.se.^2 + x.sn.^2);

% Vertical deviation
x.dver = abs(x.su);

% Sort values in ascending order
hor=sort(x.dhor);
ver=sort(x.dver);
%pr=sort(y.prResRms);

% Percentual indexes
x.Index50=floor(size(x.X,2)*0.5) + 1;
x.Index95=floor(size(x.X,2)*0.95) + 1;

% Horisontal stats
x.hor.Error50=hor(x.Index50);
x.hor.Error95=hor(x.Index95);
x.hor.Max=max(x.dhor);
x.hor.stdDev=std(x.dhor);
%%RMS calculation
% RMS w.r.t. true coordinates
x.RMSx = sqrt(sum((x.X-x.truex).^2)/length(x.X));
x.RMSy = sqrt(sum((x.Y-x.truey).^2)/length(x.Y));
x.RMSz = sqrt(sum((x.Z-x.truez).^2)/length(x.Z));
%Compute horizontal, vertical and three dimentional RMS w.r.t. true coordinates
x.hor.RMS=sqrt(x.RMSx^2 + x.RMSy^2);

x.hor.mean = mean(x.dhor);
x.hor.nr = size(x.dhor,2);

% Vertical stats
x.ver.Error50=ver(x.Index50);
x.ver.Error95=ver(x.Index95);
x.ver.Max=max(x.dver);
x.ver.stdDev=std(x.dver);
x.ver.RMS=sqrt(x.RMSz^2);
x.RMS3D = sqrt(x.RMSx^2 + x.RMSy^2 + x.RMSz^2);
x.ver.mean = mean(x.dver);
x.ver.nr = size(x.dver,2);


x.dop.gdop=mean(dop(:,1));
x.dop.pdop=mean(dop(:,2));
x.dop.hdop=mean(dop(:,3));
x.dop.vdop=mean(dop(:,4));
x.dop.tdop=mean(dop(:,5));
x.fom=fom;

x.ppp.truex = x.truex;
x.ppp.truey = x.truey;
x.ppp.truez = x.truez;

x.ppp.meanx = x.meanx;
x.ppp.meany = x.meany;
x.ppp.meanz = x.meanz;

% Select reference to mean position
xr=x.ppp.meanx;
yr=x.ppp.meany;
zr=x.ppp.meanz;

sn	= (x.topo(1,1)*(x.X-xr) + x.topo(1,2)*(x.Y-yr) + x.topo(1,3)*(x.Z-zr));
se	= (x.topo(2,1)*(x.X-xr) + x.topo(2,2)*(x.Y-yr) + x.topo(2,3)*(x.Z-zr));
su	= (x.topo(3,1)*(x.X-xr) + x.topo(3,2)*(x.Y-yr) + x.topo(3,3)*(x.Z-zr));
hor = sqrt(se.^2 + sn.^2);

x.ppp.mean.se = se;
x.ppp.mean.sn = sn;
x.ppp.mean.su = su;

a = sort(abs(se));
%x.ppp.mean.dev_std_e = std(se);
x.ppp.mean.dev_cep50_e = a(x.Index50);
x.ppp.mean.dev_cep95_e = a(x.Index95);
x.ppp.mean.dev_max_e = max(abs(se));

a = sort(abs(sn));
x.ppp.mean.dev_cep50_n = a(x.Index50);
x.ppp.mean.dev_cep95_n = a(x.Index95);
x.ppp.mean.dev_max_n = max(abs(sn));

a = sort(abs(hor));
x.ppp.mean.dev_cep50_h = a(x.Index50);
x.ppp.mean.dev_cep95_h = a(x.Index95);
x.ppp.mean.dev_max_h = max(abs(hor));

a = sort(abs(su));
x.ppp.mean.dev_cep50_u = a(x.Index50);
x.ppp.mean.dev_cep95_u = a(x.Index95);
x.ppp.mean.dev_max_u = max(abs(su));

% Select reference to true position
xr=x.ppp.truex;
yr=x.ppp.truey;
zr=x.ppp.truez;

sn	= (x.topo(1,1)*(x.X-xr) + x.topo(1,2)*(x.Y-yr) + x.topo(1,3)*(x.Z-zr));
se	= (x.topo(2,1)*(x.X-xr) + x.topo(2,2)*(x.Y-yr) + x.topo(2,3)*(x.Z-zr));
su	= (x.topo(3,1)*(x.X-xr) + x.topo(3,2)*(x.Y-yr) + x.topo(3,3)*(x.Z-zr));

hor = sqrt(se.^2 + sn.^2);
x.ppp.true.se = se;
x.ppp.true.sn = sn;
x.ppp.true.su = su;

x.ppp.true.off_n = mean(sn);
x.ppp.true.off_e = mean(se);
x.ppp.true.off_h = mean(hor);
x.ppp.true.off_u = mean(su);

a = sort(abs(se));
x.ppp.true.dev_cep50_e = a(x.Index50);
x.ppp.true.dev_cep95_e = a(x.Index95);
x.ppp.true.dev_max_e = max(abs(se));

a = sort(abs(sn));
x.ppp.true.dev_cep50_n = a(x.Index50);
x.ppp.true.dev_cep95_n = a(x.Index95);
x.ppp.true.dev_max_n = max(abs(sn));

a = sort(abs(hor));
x.ppp.true.dev_cep50_h = a(x.Index50);
x.ppp.true.dev_cep95_h = a(x.Index95);
x.ppp.true.dev_max_h = max(abs(hor));

a = sort(abs(su));
x.ppp.true.dev_cep50_u = a(x.Index50);
x.ppp.true.dev_cep95_u = a(x.Index95);
x.ppp.true.dev_max_u = max(abs(su));

figure;
plot([1:1:length(x.se)],x.se,'b-*'); hold on; grid on;
plot([1:1:length(x.sn)],x.sn,'g-+'); 
plot([1:1:length(x.su)],x.su,'r-o');  
legend('E','N','U');
xlabel('Time (s)');
ylabel('Deviation (m)');
title('Coordinate variation with respect to true position');

end