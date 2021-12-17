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
function dop = getDOPValues(const, H, XYZ)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculates dop values from H matrix
% 
% Input:
%  const  - System constant used in the receiver
%   H     - Directional cosine matrix
%  XYZ    - Observed position in ECEF
%
% Output:
%   dop   - Vector with DOP values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nrofSystems=length(H(1,:))-3;
dop=4+nrofSystems; %size dop vector

% Calculate DOP 
dop     = zeros(1,dop);
Q       = inv(H'*H);
dop(1)  = sqrt(trace(Q));                       % GDOP    
dop(2)  = sqrt(Q(1,1) + Q(2,2) + Q(3,3));       % PDOP
% In order to compute 'HDOP' and 'VDOP', we need to convert from ECEF to
% LLA

[dphi, dlambda, h] = convXyz2Geod(const, XYZ);
 
% %Conversion from degree to radian
phi = dphi/180;
lambda = dlambda/180;

% rotation matrix  'R_ENU'
R_ENU = [-sin(lambda) -sin(phi)*cos(lambda) cos(lambda)*cos(phi);
         cos(lambda)  -sin(phi)*sin(lambda) cos(phi)*sin(lambda);
         0            cos(phi)              sin(phi)];

Q_ECEF = Q(1:3,1:3);
% Calculate the local Co-factor matrix
Q_ENU = R_ENU'*Q_ECEF*R_ENU;
% Calculate 'HDOP' and 'VDOP' 
HDOP = sqrt(Q_ENU(1,1)+ Q_ENU(2,2));
VDOP = sqrt(Q_ENU(3,3));

dop(3)  = HDOP;                % HDOP
dop(4)  = VDOP;                % VDOP
dop(5)  = sqrt(Q(4,4));        % TDOP system1

% TDOP for other systems
if nrofSystems==2
    dop(6)  = sqrt(Q(5,5));                         
elseif nrofSystems==3
    dop(7)  = sqrt(Q(6,6));
elseif nrofSystems==4
    dop(8)  = sqrt(Q(7,7));
end