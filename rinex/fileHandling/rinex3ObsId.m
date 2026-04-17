%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright 2015-2026 Finnish Geospatial Research Institute FGI, National
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
classdef rinex3ObsId < handle
% RINEX3OBSID observation identification
%
% rinex 3.xx specifies observation id based on three variables,
% tracking mode, carrier frequency band and observable type (in short tna).
% Given a particular combination of tna, observation id can be ambiguous
% if the satellite system is not specified.
%
% properties:
%   trackingMode:trackingMode
%   carrierBand:carrierBand
%   observationType:obsType
%   system:satSysId
%
% methods:
%   bool=isvalid
%   char=as3letter
%   from3letter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        trackingMode
        carrierBand
        observationType
        system
    end

    methods

        function obj=rinex3ObsId(tm,cb,ot,s)
        % RINEX3OBSID
        %   rinex3ObsId(obj,tm,cb,ot)
        %   tm:trackingMode
        %   cb:carrierBand
        %   ot:obsType
        %   s:satSysId

        if nargin < 4
            obj.trackingMode=trackingMode.unknown;
            obj.carrierBand=carrierBand.unknown;
            obj.observationType=obsType.unknown;
            obj.system=satSysId.systemUnknown;
        else
            obj.trackingMode=tm;
            obj.carrierBand=cb;
            obj.observationType=ot;
            obj.system=s;
        end
        end
        % end of function rinex3ObsId(obj,tm,cb,ot)

        %======================
        function b=isValid(obj)
        % RINEX3OBSID.ISVALID
        % isValid() returns false, if either of the tna or the
        % satellite system is unknown by definition.

        if (obj.trackingMode==trackingMode.unknown ||...
            obj.carrierBand==carrierBand.unknown ||...
            obj.observationType==obsType.unknown||...
            obj.system==satSysId.systemUnknown)
            b=false;
        else
            b=true;
        end
        end
        % end of function isValid

        %========================
        function c=as3letter(obj)
        %AS3LETTER
        % as3letter() returns a char vector representaion of tna.
        % c:char
        % raises warning in case either of the t,n,a are unknown.

        c=repmat(' ',1,3);
        switch obj.observationType
            case obsType.range
                c(1)='C';
            case obsType.phase
                c(1)='L';
            case obsType.doppler
                c(1)='D';
            case obsType.snr
                c(1)='S';
            case obsType.iono
                c(1)='I';
            case obsType.channel
                c(1)='X';
            case obsType.unknown
                c(1)='U';
                warning('rinex3ObsId:invalid',...
                    'obsType is unkown and/or missing.')
        end
        
        switch obj.carrierBand
            case carrierBand.X
                c(2)='0';
            
            case {carrierBand.L1,carrierBand.G1,carrierBand.E1,...
                  carrierBand.B1}
                c(2)='1';
            
            case {carrierBand.L2,carrierBand.G2,carrierBand.B12}
                c(2)='2';

            case carrierBand.G3
                c(2)='3';
                
            case carrierBand.G1a
                c(2)='4';

            case {carrierBand.L5,carrierBand.E5a,carrierBand.B2a}
                c(2)='5';

            case {carrierBand.G2a,carrierBand.E6,carrierBand.L6,...
                  carrierBand.B3}
                c(2)='6';

            case {carrierBand.E5b,carrierBand.B2b}
                c(2)='7';

            case {carrierBand.E5,carrierBand.B2}
                c(2)='8';

            case carrierBand.S
                c(2)='9';

            case carrierBand.unknown
                c(2)='U';
                warning('rinex3ObsId:invalid',...
                'carrierBand is unknown and/or missing.');
        end

        switch obj.trackingMode
            case {trackingMode.A}
                c(3)='A';

            case {trackingMode.B}
                c(3)='B';

            case {trackingMode.CA}
                c(3)='C';

            case {trackingMode.DD}
                c(3)='D';

            case {trackingMode.P}
                c(3)='L';

            case {trackingMode.I}
                c(3)='I';

            case {trackingMode.M}
                c(3)='M';

            case {trackingMode.N}
                if obj.observationType==obsType.range
                    error('rinex3ObsId:invalid',...
                        'codeless tracking mode can not measure pseudo-range.')
                end
                c(3)='N';

            case {trackingMode.PP}
                c(3)='P';

            case {trackingMode.Q}
                c(3)='Q';

            case {trackingMode.D}
                c(3)='S';

            case {trackingMode.DP,trackingMode.IQ}
                c(3)='X';

            case {trackingMode.Y}
                c(3)='Y';

            case {trackingMode.ZZ}
                c(3)='Z';

            case {trackingMode.Z}
                c(3)='W';

            case trackingMode.unknown
                c(3)='U';
                warning('rinex3ObsId:invalid',...
                'tackingMode is unknown and/or missing.');
        end
        
        end
        %end of function as3letter()

        %============================
        function from3letter(obj,i,s)
        % FROM3LETTER
        % from3letter(i,s) determines properties of an instantiation of the
        % rinex3ObsId class based on char i and satSysId s.
        % i:char
        %   array of three characters
        % s:satSysId
        if ~isa(s,'satSysId')
            error('rinex3ObsId:incorrectType',...
                's must be of type satSysId, but not %s',class(s))
        end
        
        if length(s)>1
            error('rinex3ObsId:badInput',...
                's can not be an array with more than one object.')
        end
        
        if ~ischar(i)
            error('rinex3ObsId:incorrectType',...
                'i must be of type char, but not %s',class(i))
        end
        
        if length(i)~=3
            error('rinex3ObsId:badInput',...
                'i mut be an array of 3 char objects.')
        end

        if s==satSysId.systemUnknown
            error('rinex3ObsId:invalid',...
                'satellite system is satSysId.systemUnknown.')
        elseif s==satSysId.systemMixed
            error('satellite system is satSysId.systemMixed.')
        else
            obj.system=s;
        end

        switch i(1)
            case 'C'
                obj.observationType=obsType.range;
            case 'L'
                obj.observationType=obsType.phase;
            case 'D'
                obj.observationType=obsType.doppler;
            case 'S'
                obj.observationType=obsType.snr;
            case 'I'
                obj.observationType=obsType.iono;
            case 'X'
                obj.observationType=obsType.channel;
            case 'U'
                obj.observationType=obsType.unknown;
                warning('rinex3ObsId:invalid',...
                    'observationType is unknown.')
            otherwise
                error('rinex3ObsId:invalid',...
                    '%c-- is invalid observation type identifier.',i(1))
        end
        
        switch i(2)
            case '0'
                obj.carrierBand=carrierBand.X;
            case '1'
                switch obj.system
                    case {satSysId.systemGPS,satSysId.systemQZSS,...
                          satSysId.systemSBAS}
                        obj.carrierBand=carrierBand.L1;
                    case satSysId.systemGLONASS
                        obj.carrierBand=carrierBand.G1;
                    case satSysId.systemGalileo
                        obj.carrierBand=carrierBand.E1;
                    case satSysId.systemBDS
                        obj.carrierBand=carrierBand.B1;
                end
            case '2'
                switch obj.system
                    case {satSysId.systemGPS,satSysId.systemQZSS}
                        obj.carrierBand=carrierBand.L2;
                    case satSysId.systemGLONASS
                        obj.carrierBand=carrierBand.G2;
                    case satSysId.systemBDS
                        obj.carrierBand=carrierBand.B12;
                end
            case '3'
                obj.carrierBand=carrierBand.G3;
            case '4'
                obj.carrierBand=carrierBand.G1a;
            case '5'
                switch obj.system
                    case {satSysId.systemGPS,satSysId.systemQZSS,...
                            satSysId.systemSBAS,satSysId.systemIRNSS}
                        obj.carrierBand=carrierBand.L5;
                    case satSysId.systemGalileo
                        obj.carrierBand=carrierBand.E5a;
                    case satSysId.systemBDS
                        obj.carrierBand=carrierBand.B2a;
                end
            case '6'
                switch obj.system
                    case satSysId.systemGalileo
                        obj.carrierBand=carrierBand.E6;
                    case satSysId.systemQZSS
                        obj.carrierBand=carrierBand.L6;
                    case satSysId.systemBDS
                        obj.carrierBand=carrierBand.B3;
                    case satSysId.systemGLONASS
                        obj.carrierBand=carrierBand.G2a;
                end
            case '7'
                switch obj.system
                    case satSysId.systemGalileo
                        obj.carrierBand=carrierBand.E5b;
                    case satSysId.systemBDS
                        obj.carrierBand=carrierBand.B2b;
                end
            case '8'
                switch obj.system
                    case satSysId.systemGalileo
                        obj.carrierBand=carrierBand.E5;
                    case satSysId.systemBDS
                        obj.carrierBand=carrierBand.B2;
                end
            case '9'
                obj.carrierBand=carrierBand.S;
            otherwise
                error('rinex3ObsId:invalid',...
                    '%c is not a valid carrier frequency band',i(2))
        end

        switch i(3)
            case 'A'
                obj.trackingMode=trackingMode.A;
            case 'B'
                obj.trackingMode=trackingMode.B;
            case 'C'
                obj.trackingMode=trackingMode.CA;
            case 'D'
                obj.trackingMode=trackingMode.DD;
            case 'I'
                obj.trackingMode=trackingMode.I;
            case 'L'
                obj.trackingMode=trackingMode.P;
            case 'M'
                obj.trackingMode=trackingMode.M;
            case 'N'
                obj.trackingMode=trackingMode.N;
            case 'P'
                obj.trackingMode=trackingMode.PP;
            case 'Q'
                obj.trackingMode=trackingMode.Q;
            case 'S'
                obj.trackingMode=trackingMode.D;
            case 'W'
                obj.trackingMode=trackingMode.Z;
            case 'X'
                switch obj.system
                    case satSysId.systemGPS
                        switch obj.carrierBand
                            case {carrierBand.L1,carrierBand.L2}
                                obj.trackingMode=trackingMode.DP;
                            case carrierBand.L5
                                obj.trackingMode=trackingMode.IQ;
                        end
                    case satSysId.systemGLONASS
                        switch obj.carrierBand
                            case {carrierBand.G1a,carrierBand.G2a}
                                obj.trackingMode=trackingMode.DP;
                            case trackingMode.G3
                                obj.trackingMode=trackingMode.IQ;
                        end
                    case satSysId.systemGalileo
                        switch obj.carrierBand
                            case {carrierBand.E1,carrierBand.E6}
                                obj.trackingMode=trackingMode.DP;
                            case {carrierBand.E5a,carrierBand.E5b,carrierBand.E5}
                                obj.trackingMode=trackingMode.IQ;
                        end
                    case satSysId.systemIRNSS
                        obj.trackingMode=trackingMode.DP;
                    case satSysId.systemQZSS
                        switch obj.carrierBand
                        case carrierBand.L5
                            obj.trackingMode=trackingMode.IQ;
                        case {carrierBand.L2,carrierBand.L6}
                            obj.trackingMode=trackingMode.DP;
                        end
                        %obj.trackingMode=trackingMode.DP;
                    case satSysId.systemBDS
                        switch obj.carrierBand
                            case {carrierBand.B1,carrierBand.B2}
                                obj.trackingMode=trackingMode.DP;
                            case {carrierBand.B12,carrierBand.B2b,carrierBand.B3}
                                obj.trackingMode=trackingMode.IQ;
                        end
                    case satSysId.systemSBAS
                        obj.trackingMode=trackingMode.IQ;
                end
            case 'Y'
                obj.trackingMode=trackingMode.Y;
            case 'Z'
                obj.trackingMode=trackingMode.ZZ;
            otherwise
                error('rinex3ObsId:invalid',...
                    '%c is not a valid tracking mode.',i(3))
        end
        end
        % end of function from3letter

        %===============================
        function set.trackingMode(obj,i)
        [m,~]=enumeration('trackingMode');
        if ~ismember(i,m')
            error('rinex3ObsId:incorrectType',...
                'input must be of trackingMode type, but not %s.',class(i));
        elseif length(i)>1
            error('rinex3ObsId:incorrectLength',...
                'input must be of length 1, but not of length %u',length(i))
        else
            obj.trackingMode=i;
        end
        end
        %end of function set.trackingMode(obj,i)

        %===============================
        function set.carrierBand(obj,i)
        [m,~]=enumeration('carrierBand');
        if ~ismember(i,m')
            error('rinex3ObsId:incorrectType',...
                'input must be of carrierBand type, but not %s.',class(i));
        elseif length(i)>1
            error('rinex3ObsId:incorrectLength',...
                'input must be of length 1, but not of length %u',length(i))
        else
            obj.carrierBand=i;
        end
        end
        %end of function set.carrierBand(obj,i)

        %===================================
        function set.observationType(obj,i)
        [m,~]=enumeration('obsType');
        if ~ismember(i,m')
            error('rinex3ObsId:incorrectType',...
                'input must be of obsType type, but not %s.',class(i));
        elseif length(i)>1
            error('rinex3ObsId:incorrectLength',...
                'input must be of length 1, but not on length %u',length(i))
        else
            obj.observationType=i;
        end
        end
        %end of function set.observationType(obj,i)

        %=========================
        function set.system(obj,i)
        [m,~]=enumeration('satSysId');
        if ~ismember(i,m')
            error('rinex3ObsId:incorrectType',...
                'input must be of satSysId type, but not %s',class(i))
        elseif length(i)>1
            error('rinex3ObsId:incorrectLength',...
                'input must be of length 1, but not length %u',length(i))
        else
            obj.system=i;
        end
        end
        % end of function set.system()

    end
    % end of methods
end
