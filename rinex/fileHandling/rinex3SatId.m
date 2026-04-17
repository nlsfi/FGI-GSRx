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
classdef rinex3SatId < handle

% RINEX3SATID satellite identification.

% properties:
%   p:double
%   system:satSysId
%
% methods:
%   [bool,bool]=isValid
%   c=aschar
%   bool=isSameSatellite
%   str=as3letter()
%   from3letter()
%   fromchar()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    properties
        p           % satellite identification number e.g., prn
        system      % satellite system
    end

    methods

        %============================
        function obj=rinex3SatId(s,p)
        switch nargin
            case 2
                obj.p=p;
                obj.system=s;
            case 1
                obj.p=-1;
                obj.system=s;
            otherwise
                obj.p=-1;
                obj.system=satSysId.systemUnknown;
        end
        end
        % end of function obj=rinex3SatId(s,p)

        %================================
        function b=isSameSatellite(obj,i)
        % RINEX3SATID.ISSAMESATELLITE
        % returns true if both p and system of i are the same as the obj.
        if ~isa(i,'rinex3SatId')
            error('rinex3SatId:incorrectType',...
                'input must be of rinex3SatId type, but not %s',class(i))
        end
        if(obj.system==i.system && obj.p==i.p)
            b=true;
        else
            b=false;
        end
        end
        % end of isSameSatellite

        %============================
        function [bs,bp]=isValid(obj)
        % RINEX3SATID.ISVALID
        % verifies if satellite identification number and
        % satellite constellation are both known
        if obj.system~=satSysId.systemUnknown
            bs=true;
        else
            bs=false;
        end

        if obj.p>1
            % TODO system-wise check (e.g., GPS [1:32] is valid only)
            bp=true;
        else
            bp=false;
        end
        end

        %====================
        function c=aschar(obj)
        % RINEX3SATID.ASCHAR returns a char to specify the satellite system.
        % raises a warning if the satellite system is satSysId.systemUnknown.
        switch obj.system
            case satSysId.systemGPS
                c='G';
            case satSysId.systemGLONASS
                c='R';
            case satSysId.systemGalileo
                c='E';
            case satSysId.systemQZSS
                c='J';
            case satSysId.systemBDS
                c='C';
            case satSysId.systemIRNSS
                c='I';
            case satSysId.systemSBAS
                c='S';
            case satSysId.systemMixed
                c='M';
            otherwise
                warning('rinex3SatId:badSystem',...
                    'system is unknown and/or missing.')
                c='U';
        end
        end
        %end of function c=aschar(obj)

        %========================
        function s=as3letter(obj)
        % RINEX3SATID.AS3LETTER returns 3 char vector.
        % raises error if satellite system is satSysId.systemSBAS
        % or satSysId.systemMixed.
        % raises error if it is satSysId.systemUnknown.

        switch obj.system
            case satSysId.systemGPS
                s='GPS';
            case satSysId.systemGLONASS
                s='GLO';
            case satSysId.systemGalileo
                s='GAL';
            case satSysId.systemQZSS
                s='QZS';
            case satSysId.systemBDS
                s='BDT';
            case satSysId.systemIRNSS
                s='IRN';
            case satSysId.systemSBAS
                % not mentioned in rinex 304.pdf
                error('rinex3SatId:notImplemented',...
                    '3-letter SBAS id is not implemented.');
            case satSysId.systemMixed
                % not mentioned in rinex 304.pdf
                error('rinex3SatId:notImplemented',...
                    '3-letter Mixed id is not implemented.');
            case satSysId.systemUnknown
                warning('rinex3SatId:badSystem',...
                    'system is unknown and/or missing.');
                s='UNK';
        end
        end
        % end of function s=as3letter(obj) 

        %=======================
        function fromchar(obj,i)
        % FROMCHAR
        % fromchar(i) sets system property of an instantiation
        % of rinex3SatId based on character variable i.
        % i:char
        if ~ischar(i)
            error('rinex3SatId:incorrectType',...
                'input must be of chr type, but not %s',class(i))
        else
            if length(i)>1
                error('rinex3SatId:badInput',...
                   'input must be of size (1,1)')
            else
                switch i
                    case 'G'
                        obj.system=satSysId.systemGPS;
                    case 'R'
                        obj.system=satSysId.systemGLONASS;
                    case 'E'
                        obj.system=satSysId.systemGalileo;
                    case 'J'
                        obj.system=satSysId.systemQZSS;
                    case 'C'
                        obj.system=satSysId.systemBDS;
                    case 'I'
                        obj.system=satSysId.systemIRNSS;
                    case 'S'
                        obj.system=satSysId.systemSBAS;
                    case 'M'
                        obj.system=satSysId.systemMixed;
                end
                obj.p=-1;
            end
        end
        end
        % end of function fromchar

        %==========================
        function from3letter(obj,i)
        % FROM3LETTER
        % from3letter(i) does the same thing as fromchar(i) except
        % the input i is a vector of 3 characters.
        % i:char
        if ~ischar(i)
            error('rinex3SatId:incorrectType',...
                'input must be of chr type, but not %s',class(i))
        else
            if length(i)~=3
                error('rinex3SatId:badInput',...
                   'input must be of size (3,1)')
            else
                switch i
                    case 'GPS'
                        obj.system=satSysId.systemGPS;
                    case 'GLO'
                        obj.system=satSysId.systemGLONASS;
                    case 'GAL'
                        obj.system=satSysId.systemGalileo;
                    case 'QZS'
                        obj.system=satSysId.systemQZSS;
                    case 'BDT'
                        obj.system=satSysId.systemBDS;
                    case 'IRN'
                        obj.system=satSysId.systemIRNSS;
                end
                obj.p=-1;
            end
        end
        end
        % end of function from3letter

        %====================
        function set.p(obj,i)
        if ~isa(i,'double')
            error('rinex3SatId:incorrectType',...
                'input must be of double type, but not %s',class(i))
        else
            obj.p=i;
        end
        end
        %end of function set.p(obj,i)

        %=========================
        function set.system(obj,i)
        [m,~]=enumeration('satSysId');
        if ~ismember(i,m')
            error('rinex3SatId:incorrectType',...
                'input must be of satSysId type, not a %s.',class(i));
        else
            obj.system=i;
        end
        end
        % end of function set.p(obj,i)

    end
    % end of methods

end
