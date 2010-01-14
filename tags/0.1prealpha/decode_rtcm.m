function [data] = decode_rtcm(msg)

% SYNTAX:
%   [data] = decode_rtcm(msg)
%
% INPUT:
%   msg = binary message received from the master station
%
% OUTPUT:
%   data = cell-array that contains the decoded RTCM messages
%          (packet number is in the first cell-array field)
%
% DESCRIPTION:
%   RTCM 3.1 binary messages decoding (also in sequence).

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1 pre-alpha
%
% Copyright (C) 2009 Mirko Reguzzoni*, Eugenio Realini*
%
% * Laboratorio di Geomatica, Polo Regionale di Como, Politecnico di Milano, Italy
%----------------------------------------------------------------------------------------------
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%----------------------------------------------------------------------------------------------

%----------------------------------------------------------------------------------------------
% MESSAGE ID CODE
%----------------------------------------------------------------------------------------------

preamble = '11010011';      % FIXED transport layer header (8 bit)
reserved = '000000';        % reserved field (6 bit). It could change in the future!

codeBIN = [preamble reserved];      % binary initial stream

pos = findstr(msg, codeBIN);        % message initial index

%----------------------------------------------------------------------------------------------
% MESSAGE IDENTIFICATION
%----------------------------------------------------------------------------------------------

% output variable initialization
data = cell(0);

% if there is at least one RTCM messagge
if ~isempty(pos)

    % initial index of the first message
    pos = pos(1);

    % counter initialization
    i = 0;

    while (pos <= length(msg)) & (strcmp(msg(pos:pos+13),codeBIN))

        %msg(pos:pos+13)

        % counter increment
        i = i + 1;

        % skip the "preamble" (8 bit) and "reserved" (6 bit) fields
        pos = pos + 14;

        if (pos + 9 <= length(msg))

            % message lenght (10 bit)
            LEN = bin2dec(msg(pos:pos+9));  pos = pos + 10;

            if (pos + 8*LEN - 1 <= length(msg))

                % message number (12 bit)
                DF002 = bin2dec(msg(pos:pos+11));

                % message identification
                switch DF002
                    
                    % GPS observations on L1 carrier
                    case 1001
                        [data(:,i)] = decode_1001(msg(pos:pos+8*LEN-1));

                    % GPS observations on L1 carrier
                    case 1002
                        [data(:,i)] = decode_1002(msg(pos:pos+8*LEN-1));
                        
                    % GPS observations on L1/L2 carrier
                    case 1003
                        [data(:,i)] = decode_1003(msg(pos:pos+8*LEN-1));

                    % GPS observations on L1/L2 carrier
                    case 1004
                        [data(:,i)] = decode_1004(msg(pos:pos+8*LEN-1));

                    % master station coordinates
                    case 1005
                        [data(:,i)] = decode_1005(msg(pos:pos+8*LEN-1));

                    % master station coordinates + antenna height
                    case 1006
                        [data(:,i)] = decode_1006(msg(pos:pos+8*LEN-1));

                    % antenna description
                    case 1007
                        [data(:,i)] = decode_1007(msg(pos:pos+8*LEN-1));

                    % antenna description + serial number
                    case 1008
                        [data(:,i)] = decode_1008(msg(pos:pos+8*LEN-1));
                        
                    % GLONASS observations on L1 carrier
                    case 1009
                        [data(:,i)] = decode_1009(msg(pos:pos+8*LEN-1));

                    % GLONASS observations on L1 carrier
                    case 1010
                        [data(:,i)] = decode_1010(msg(pos:pos+8*LEN-1));
                        
                    % GLONASS observations on L1/L2 carrier
                    case 1011
                        [data(:,i)] = decode_1011(msg(pos:pos+8*LEN-1));

                    % GLONASS observations on L1/L2 carrier
                    case 1012
                        [data(:,i)] = decode_1012(msg(pos:pos+8*LEN-1));
                        
                    % system parameters
                    case 1013
                        [data(:,i)] = decode_1013(msg(pos:pos+8*LEN-1));
                        
                    % auxiliary network information
                    case 1014
                        [data(:,i)] = decode_1014(msg(pos:pos+8*LEN-1));
                        
                    % ionospheric correction differences
                    case 1015
                        [data(:,i)] = decode_1015(msg(pos:pos+8*LEN-1));
                    
                    % geometric correction differences
                    case 1016
                        [data(:,i)] = decode_1016(msg(pos:pos+8*LEN-1));
                        
                    % combined ionospheric and geometric correction differences
                    case 1017
                        [data(:,i)] = decode_1017(msg(pos:pos+8*LEN-1));

                    % other informations: satellite ephemerides
                    case 1019
                        [data(:,i)] = decode_1019(msg(pos:pos+8*LEN-1));
                        
                    %GLONASS ephemerides    
                    case 1020
                        [data(:,i)] = decode_1020(msg(pos:pos+8*LEN-1));
                end

            end

            pos = pos + 8*LEN;

        else
            pos = pos + 10;
        end

        % skip the 24 bits of CRC
        pos = pos + 24;

        % message ending byte
        while (mod(pos,8) ~= 1)
            pos = pos + 1;
        end

        %msg(pos:pos+13)
        %pause

    end
end