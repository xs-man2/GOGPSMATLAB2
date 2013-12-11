function [data] = decode_1003(msg)

% SYNTAX:
%   [data] = decode_1003(msg)
%
% INPUT:
%   msg = binary message received from the master station
%
% OUTPUT:
%   data = cell-array that contains the 1003 packet information
%          1.1)  DF002 = message number = 1003
%          2.1)  DF003 = reference station id
%          2.2)  (DF004 / 1000) = time of week in seconds (GPS epoch)
%          2.3)  DF005 = are there other messages of the same epoch? YES=1, NO=0
%          2.4)  DF006 = number of visible satellites
%          2.5)  DF007 = phase-smoothed code? YES SI=1, NO=0
%          2.6)  DF008 = smoothing window
%          3.1)  DF010 = code type vector on L1: C/A=0, P=1
%          3.2)  (DF011 * 0.02)= code observation vector on L1
%          3.3)  (code observation L1 + (DF012*0.0005)) / lambda1 = phase observation vector on L1
%          3.4)  DF013 = how long L1 has been locked? index vector (cycle-slip=0)
%          3.5)  DF016 = code type vector on  L2: C/A=0, P_direct=1, P_cross_corr=2, P_corr=3
%          3.6)  ((DF011 + DF017) * 0.02) + (DF014 * 299792.458) = code observation vector on L2
%          3.7)  (code observation L1 + (DF018*0.0005)) / lambda2 = phase observation vector on L2
%          3.8)  DF019 = how long L2 has been locked? index vector (cycle-slip=0)
%
% DESCRIPTION:
%   RTCM format 1003 message decoding.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1 alpha
%
% Copyright (C) 2009-2010 Mirko Reguzzoni*, Eugenio Realini**, Sara Lucca*
%
% * Laboratorio di Geomatica, Polo Regionale di Como, Politecnico di Milano, Italy
% ** Graduate School for Creative Cities, Osaka City University, Japan
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

%carriers wavelenght
global lambda1 lambda2

%message pointer initialization
pos = 1;

%output variable initialization
data = cell(3,1);
data{1} = 0;
data{2} = zeros(6,1);
data{3} = zeros(32,8);

%message number = 1003
DF002 = bin2dec(msg(pos:pos+11));  pos = pos + 12;

%reference station id
DF003 = bin2dec(msg(pos:pos+11));  pos = pos + 12;

%TOW = time of week in milliseconds
DF004 = bin2dec(msg(pos:pos+29));  pos = pos + 30;

%other synchronous RTCM messages flag (YES=1, NO=0)
DF005 = bin2dec(msg(pos));  pos = pos + 1;

%number of visible satellites
DF006 = bin2dec(msg(pos:pos+4));  pos = pos + 5;

%phase-smoothed code flag (YES=1, NO=0)
DF007 = bin2dec(msg(pos));  pos = pos + 1;

%smoothing window
DF008 = bin2dec(msg(pos:pos+2));  pos = pos + 3;

%output data save
data{1} = DF002;
data{2}(1) = DF003;
data{2}(2) = DF004 / 1000;
data{2}(3) = DF005;
data{2}(4) = DF006;
data{2}(5) = DF007;
data{2}(6) = DF008;

%-------------------------------------------------

%number of satellites
NSV = data{2}(4);

%data decoding for each satellite
for i = 1 : NSV

    %analyzed satellite number
    SV = bin2dec(msg(pos:pos+5));  pos = pos + 6;

    %if GPS satellite
    if (SV >= 1 & SV <= 32)

        %L1 code type (C/A=0, P=1)
        DF010 = bin2dec(msg(pos));  pos = pos + 1;

        %L1 pseudorange
        DF011 = bin2dec(msg(pos:pos+23));  pos = pos + 24;

        %L1 phaserange - L1 pseudorange
        DF012 = twos_complement(msg(pos:pos+19));  pos = pos + 20;

        %L1 lock-time index (see Table 4.3-2 on RTCM manual)
        DF013 = bin2dec(msg(pos:pos+6));  pos = pos + 7;

        %---------------------------------------------------------

        %L2 code type (C/A=0, P=1,2,3)
        DF016 = bin2dec(msg(pos:pos+1));  pos = pos + 2;

        %L2-L1 pseudorange
        DF017 = twos_complement(msg(pos:pos+13));  pos = pos + 14;

        %L2 phaserange - L1 pseudorange
        DF018 = twos_complement(msg(pos:pos+19));  pos = pos + 20;

        %indice di lock-time L2 (vedi Tabella 4.3-2 su manuale RTCM)
        DF019 = bin2dec(msg(pos:pos+6));  pos = pos + 7;

        %---------------------------------------------------------

        %output data save
        data{3}(SV,1)  = DF010;
        data{3}(SV,2)  = (DF011 * 0.02);
        data{3}(SV,3)  = (data{3}(SV,2) + (DF012*0.0005)) / lambda1;
        data{3}(SV,4)  = DF013;
        data{3}(SV,5)  = DF016;
        data{3}(SV,6)  = (data{3}(SV,2) + (DF017 * 0.02));
        data{3}(SV,7)  = (data{3}(SV,2) + (DF018*0.0005)) / lambda2;
        data{3}(SV,8)  = DF019;

    else %SBAS satellites

        %do not store SBAS satellite information
        pos = pos + 95;

    end

end