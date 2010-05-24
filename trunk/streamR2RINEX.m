function [week] = streamR2RINEX(fileroot, filename, wait_dlg)

% SYNTAX:
%   [week] = streamR2RINEX(fileroot, filename, wait_dlg);
%
% INPUT:
%   fileroot = input file root (rover data, binary stream)
%   filename = output file name (rover data, RINEX format)
%   wait_dlg = optional handler to waitbar figure
%
% OUTPUT:
%   week = GPS week number
%
% DESCRIPTION:
%   File conversion from rover stream (UBX binary) to RINEX format.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1 beta
%
% Copyright (C) 2009-2010 Mirko Reguzzoni*, Eugenio Realini**
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

global lambda1

%----------------------------------------------------------------------------------------------

week = 0;

if (nargin == 3)
    waitbar(0.5,wait_dlg,'Reading rover stream files...')
end

%ROVER stream reading
data_rover_all = [];                                                 %overall stream
hour = 0;                                                            %hour index (integer)
hour_str = num2str(hour,'%02d');                                     %hour index (string)
d = dir([fileroot '_rover_' hour_str '.bin']);                       %file to be read
while ~isempty(d)
    if (nargin == 2)
        fprintf(['Reading: ' fileroot '_rover_' hour_str '.bin\n']);
    end
    num_bytes = d.bytes;                                             %file size (number of bytes)
    fid_rover = fopen([fileroot '_rover_' hour_str '.bin']);         %file opening
    data_rover = fread(fid_rover,num_bytes,'uint8');                 %file reading
    data_rover = dec2bin(data_rover,8);                              %conversion in binary number (N x 8bits matrix)
    data_rover = data_rover';                                        %transposed (8bits x N matrix)
    data_rover = data_rover(:)';                                     %conversion into a string (8N bits vector)
    fclose(fid_rover);                                               %file closing
    data_rover_all = [data_rover_all data_rover];                    %stream concatenation
    hour = hour+1;                                                   %hour increase
    hour_str = num2str(hour,'%02d');
    d = dir([fileroot '_rover_' hour_str '.bin']);                   %file to be read
end
clear hour hour_str d
clear data_rover fid_rover

if (nargin == 3)
    waitbar(1,wait_dlg)
end

%----------------------------------------------------------------------------------------------

if (~isempty(data_rover_all))
    
    %displaying
    if (nargin == 2)
        fprintf('Decoding rover data \n');
    end
    
    %message decoding
    if (nargin == 3)
        [cell_rover] = decode_ublox(data_rover_all, wait_dlg);
    else
        [cell_rover] = decode_ublox(data_rover_all);
    end
    clear data_rover_all
    
    %initialization (to make writing faster)
    Ncell  = size(cell_rover,2);                          %number of read RTCM packets
    time_R = zeros(Ncell,1);                              %GPS time of week
    week_R = zeros(Ncell,1);                              %GPS week
    ph1_R  = zeros(32,Ncell);                             %phase observations
    pr1_R  = zeros(32,Ncell);                             %code observations
    dop_R  = zeros(32,Ncell);                             %doppler measurements
    snr_R  = zeros(32,Ncell);                             %signal-to-noise ratio
    lock_R = zeros(32,Ncell);                             %loss of lock indicator
    Eph_R = zeros(29,32,Ncell);                           %broadcast ephemerides
    
    if (nargin == 3)
        waitbar(0,wait_dlg,'Reading rover data...')
    end
    
    i = 1;
    for j = 1 : Ncell
        if (nargin == 3)
            waitbar(j/Ncell,wait_dlg)
        end
        
        if (strcmp(cell_rover{1,j},'RXM-RAW'))            %RXM-RAW message data
            %time_R(i)   = cell_rover{2,j}(1);
            time_R(i)   = round(cell_rover{2,j}(1));
            week_R(i)   = cell_rover{2,j}(2);
            ph1_R(:,i)  = cell_rover{3,j}(:,1);
            pr1_R(:,i)  = cell_rover{3,j}(:,2);
            dop_R(:,i)  = cell_rover{3,j}(:,3);
            snr_R(:,i)  = cell_rover{3,j}(:,6);
            lock_R(:,i) = cell_rover{3,j}(:,7);
            
            %manage "nearly null" data
            pos = abs(ph1_R(:,i)) < 1e-100;
            ph1_R(pos,i) = 0;
            
            %phase adjustement
            pos = abs(ph1_R(:,i)) > 0 & abs(ph1_R(:,i)) < 1e7;
            if(sum(pos) ~= 0)
                ambig = 2^23;
                n = floor( (pr1_R(pos,i)/lambda1-ph1_R(pos,i)) / ambig + 0.5 );
                ph1_R(pos,i) = ph1_R(pos,i) + n*ambig;
            end
            
            %keep just "on top of second" measurements
            %if (time_R(i)- floor(time_R(i)) == 0)
            i = i + 1;
            %end
            
        %RXM-EPH message data save
        elseif (strcmp(cell_rover{1,j},'RXM-EPH'))
            
            %satellite number
            sat = cell_rover{2,j}(1);
            tom = cell_rover{2,j}(21);                   %time of measurement
            
            %if the ephemerides are not already available
            if (isempty(find(Eph_R(21,sat,:) ==  tom, 1)))
                Eph_R(:,sat,i) = cell_rover{2,j}(:);     %single satellite ephemerides logging
            end
        end
    end
    clear cell_rover
    clear Ncell pos sat tom
    
    %residual data erase (after initialization)
    time_R(i:end)    = [];
    week_R(i:end)    = [];
    ph1_R(:,i:end)   = [];
    pr1_R(:,i:end)   = [];
    dop_R(:,i:end)   = [];
    snr_R(:,i:end)   = [];
    lock_R(:,i:end)  = [];
    Eph_R(:,:,i:end) = [];
    
    %date decoding
    date = datevec(time_R/(3600*24) + 7*week_R + datenum([1980,1,6,0,0,0]));
    
    %----------------------------------------------------------------------------------------------
    % RINEX OBSERVATION FILE
    %----------------------------------------------------------------------------------------------
    
    %displaying
    if (nargin == 2)
        fprintf(['Writing: ' filename '.obs\n']);
    end
    
    %create RINEX observation file
    fid_obs = fopen([filename '.obs'],'wt');
    
    %write header
    fprintf(fid_obs,'     2.10           OBSERVATION DATA    G (GPS)             RINEX VERSION / TYPE\n');
    fprintf(fid_obs,'goGPS                                                       PGM / RUN BY / DATE \n');
    fprintf(fid_obs,'                                                            MARKER NAME         \n');
    fprintf(fid_obs,'                                                            OBSERVER / AGENCY   \n');
    fprintf(fid_obs,'                    u-blox                                  REC # / TYPE / VERS \n');
    fprintf(fid_obs,'                                                            ANT # / TYPE        \n');
    % fprintf(fid_obs,'%14.4f%14.4f%14.4f                  APPROX POSITION XYZ \n', XM, YM, ZM);
    fprintf(fid_obs,'        0.0000        0.0000        0.0000                  APPROX POSITION XYZ \n');
    fprintf(fid_obs,'        0.0000        0.0000        0.0000                  ANTENNA: DELTA H/E/N\n');
    fprintf(fid_obs,'     2     0                                                WAVELENGTH FACT L1/2\n');
    fprintf(fid_obs,'     4    C1    L1    S1    D1                              # / TYPES OF OBSERV \n');
    fprintf(fid_obs,'     1                                                      INTERVAL            \n');
    fprintf(fid_obs,'%6d%6d%6d%6d%6d%13.7f     GPS         TIME OF FIRST OBS   \n', ...
        date(1,1), date(1,2), date(1,3), date(1,4), date(1,5), date(1,6));
    fprintf(fid_obs,'                                                            END OF HEADER       \n');
    
    %-------------------------------------------------------------------------------
    
    %number of records
    N = length(time_R);
    
    if (nargin == 3)
        waitbar(0,wait_dlg,'Writing rover observation file...')
    end
    
    %write data
    for i = 1 : N
        if (nargin == 3)
            waitbar(i/N,wait_dlg)
        end
        
        sat = find(pr1_R(:,i) ~= 0);
        n = length(sat);
        fprintf(fid_obs,' %02d %2d %2d %2d %2d %10.7f  0 %2d', ...
            date(i,1)-2000, date(i,2), date(i,3), date(i,4), date(i,5), round(date(i,6)), n);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
        if (n>12)
            for j = 1 : 12
                fprintf(fid_obs,'G%02d',sat(j));
            end
            fprintf(fid_obs,'\n');
            fprintf(fid_obs,'%32s','');
            for j = 13 : n
                fprintf(fid_obs,'G%02d',sat(j));
            end
        else
            for j = 1 : n
                fprintf(fid_obs,'G%02d',sat(j));
            end
        end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%        
%         for j = 1 : n
%             fprintf(fid_obs,'G%02d',sat(j));
%         end
        fprintf(fid_obs,'\n');
        for j = 1 : n
            fprintf(fid_obs,'%14.3f %1d',pr1_R(sat(j),i),floor(snr_R(sat(j),i)/6));
            if (ph1_R(sat(j),i) > 1e-100)
                fprintf(fid_obs,'%14.3f%1d%1d',ph1_R(sat(j),i),lock_R(sat(j),i),floor(snr_R(sat(j),i)/6));
            else
                fprintf(fid_obs,'                ');
            end
            fprintf(fid_obs,'%14.3f %1d',snr_R(sat(j),i),floor(snr_R(sat(j),i)/6));
            fprintf(fid_obs,'%14.3f %1d',dop_R(sat(j),i),floor(snr_R(sat(j),i)/6));
            fprintf(fid_obs,'\n');
        end
    end
    
    %close RINEX observation file
    fclose(fid_obs);
    
    %----------------------------------------------------------------------------------------------
    % RINEX NAVIGATION FILE
    %----------------------------------------------------------------------------------------------
    
    %if ephemerides are available
    if (~isempty(find(Eph_R(1,:,:) ~= 0, 1)))
        
        %displaying
        if (nargin == 2)
            fprintf(['Writing: ' filename '.nav\n']);
        end
        
        %create RINEX observation file
        fid_nav = fopen([filename '.nav'],'wt');
        
        %write header
        fprintf(fid_nav,'     2.10           NAVIGATION DATA                         RINEX VERSION / TYPE\n');
        fprintf(fid_nav,'goGPS                                                       PGM / RUN BY / DATE \n');
        fprintf(fid_nav,'                                                            END OF HEADER       \n');
        
        if (nargin == 3)
            waitbar(0,wait_dlg,'Writing rover navigation file...')
        end
        
        for i = 1 : N
            if (nargin == 3)
                waitbar(i/N,wait_dlg)
            end
            
            satEph = find(Eph_R(1,:,i) ~= 0);
            for j = 1 : length(satEph)
                af2      = Eph_R(2,satEph(j),i);
                M0       = Eph_R(3,satEph(j),i);
                roota    = Eph_R(4,satEph(j),i);
                deltan   = Eph_R(5,satEph(j),i);
                ecc      = Eph_R(6,satEph(j),i);
                omega    = Eph_R(7,satEph(j),i);
                cuc      = Eph_R(8,satEph(j),i);
                cus      = Eph_R(9,satEph(j),i);
                crc      = Eph_R(10,satEph(j),i);
                crs      = Eph_R(11,satEph(j),i);
                i0       = Eph_R(12,satEph(j),i);
                idot     = Eph_R(13,satEph(j),i);
                cic      = Eph_R(14,satEph(j),i);
                cis      = Eph_R(15,satEph(j),i);
                Omega0   = Eph_R(16,satEph(j),i);
                Omegadot = Eph_R(17,satEph(j),i);
                toe      = Eph_R(18,satEph(j),i);
                af0      = Eph_R(19,satEph(j),i);
                af1      = Eph_R(20,satEph(j),i);
                tom      = Eph_R(21,satEph(j),i);
                IODE     = Eph_R(22,satEph(j),i);
                codes    = Eph_R(23,satEph(j),i);
                weekno   = Eph_R(24,satEph(j),i); %#ok<NASGU>
                L2flag   = Eph_R(25,satEph(j),i);
                svaccur  = Eph_R(26,satEph(j),i);
                svhealth = Eph_R(27,satEph(j),i);
                tgd      = Eph_R(28,satEph(j),i);
                fit_int  = Eph_R(29,satEph(j),i);
                
                %time of measurement decoding
                date = datevec(tom/(3600*24) + 7*week_R(1) + datenum([1980,1,6,0,0,0]));
                
                lineE(1,:) = sprintf('%2d %02d %2d %2d %2d %2d%5.1f% 18.12E% 18.12E% 18.12E\n', ...
                    satEph(j),date(1)-2000, date(2), date(3), date(4), date(5), round(date(6)), ...
                    af0, af1, af2);
                linesE(1,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', IODE , crs, deltan, M0);
                linesE(2,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', cuc, ecc, cus, roota);
                linesE(3,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', toe, cic, Omega0, cis);
                linesE(4,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', i0, crc, omega, Omegadot);
                linesE(5,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', idot, codes, week_R(1), L2flag);
                linesE(6,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', svaccur, svhealth, tgd, IODE);
                linesE(7,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', tom, fit_int, 0, 0);
                
                %if running on Windows, convert three-digits exponential notation
                %to two-digits; in any case, replace 'E' with 'D' and print the string
                if (~isunix)
                    lineD = strrep(lineE(1,:),'E+0','D+');
                    lineD = strrep(lineD,'E-0','D-');
                    fprintf(fid_nav,'%s',lineD);
                    for k = 1 : 7
                        lineD = strrep(linesE(k,:),'E+0','D+');
                        lineD = strrep(lineD,'E-0','D-');
                        fprintf(fid_nav,'%s',lineD);
                    end
                else
                    lineD = strrep(lineE(1,:),'E+','D+');
                    lineD = strrep(lineD,'E-','D-');
                    fprintf(fid_nav,'%s',lineD);
                    for k = 1 : 7
                        lineD = strrep(linesE(k,:),'E+','D+');
                        lineD = strrep(lineD,'E-','D-');
                        fprintf(fid_nav,'%s',lineD);
                    end
                end
            end
        end
        
        %close RINEX navigation file
        fclose(fid_nav);
        
    end
    
    %output week number
    if (~isempty(week_R))
        week = week_R(1);
    end
else
    %displaying
    if (nargin == 3)
        msgbox('No rover data acquired.');
    else
        fprintf('No rover data acquired! \n');
    end
end