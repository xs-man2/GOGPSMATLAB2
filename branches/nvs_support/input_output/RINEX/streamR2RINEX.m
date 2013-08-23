function [week] = streamR2RINEX(fileroot, filename, rinex_metadata, constellations, wait_dlg)

% SYNTAX:
%   [week] = streamR2RINEX(fileroot, filename, rinex_metadata, constellations, wait_dlg);
%
% INPUT:
%   fileroot = input file root (rover data, binary stream)
%   filename = output file name (rover data, RINEX format)
%   rinex_metadata = struct with RINEX metadata
%   constellations = struct with multi-constellation settings
%                   (see goGNSS.initConstellation - empty if not available)
%   wait_dlg = optional handler to waitbar figure
%
% OUTPUT:
%   week = GPS week number
%
% DESCRIPTION:
%   File conversion from rover binary stream to RINEX format.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.4.1 beta
%
% Copyright (C) 2009-2013 Mirko Reguzzoni, Eugenio Realini
%
% Portions of code contributed by Ivan Reguzzoni
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

global weights;
week = 0;

nSatTot = constellations.nEnabledSat;
if (nSatTot == 0)
    fprintf('No constellations selected, setting default: GPS-only\n');
    [constellations] = goGNSS.initConstellation(1, 0, 0, 0, 0, 0);
    nSatTot = constellations.nEnabledSat;
end

%check requested RINEX version
if (strcmp(rinex_metadata.version(1),'3'))
    rin_ver_id = 3;
else
    rin_ver_id = 2;
end

if (nargin == 5)
    waitbar(0.5,wait_dlg,'Reading rover stream files...')
end

%ROVER stream reading
data_rover_all = [];                                                 %overall stream
hour = 0;                                                            %hour index (integer)
hour_str = num2str(hour,'%02d');                                     %hour index (string)
d = dir([fileroot '_rover_' hour_str '.bin']);                       %file to be read
while ~isempty(d)
    if (nargin == 4)
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

%ROVER stream reading (.ubx or .stq file)
d = dir(fileroot);                                                   %file to be read
if ~isempty(d)
    if (nargin == 1)
        fprintf(['Reading: ' fileroot '\n']);
    end
    num_bytes = d.bytes;                                             %file size (number of bytes)
    fid_rover = fopen(fileroot);                                     %file opening
    data_rover_all = fread(fid_rover,num_bytes,'uint8');             %file reading
    data_rover_all = dec2bin(data_rover_all,8);                      %conversion in binary number (N x 8bits matrix)
    data_rover_all = data_rover_all';                                %transposed (8bits x N matrix)
    data_rover_all = data_rover_all(:)';                             %conversion into a string (8N bits vector)
    fclose(fid_rover);                                               %file closing
end

clear hour hour_str d
clear data_rover fid_rover

if (nargin == 5)
    waitbar(1,wait_dlg)
end

%----------------------------------------------------------------------------------------------

if (~isempty(data_rover_all))
    
    %displaying
    if (nargin == 4)
        fprintf('Decoding rover data \n');
    end
    
    %detect binary format
    header1 = 'B5';      % UBX header (hexadecimal value)
    header2 = '62';      % UBX header (hexadecimal value)
    codeHEX = [header1 header2];                % initial hexadecimal stream
    codeBIN = dec2bin(hex2dec(codeHEX),16);     % initial binary stream
    pos_UBX = findstr(data_rover_all, codeBIN); % message initial index

    header1 = 'A0';      % SkyTraq header (hexadecimal value)
    header2 = 'A1';      % SkyTraq header (hexadecimal value)
    codeHEX = [header1 header2];                % initial hexadecimal stream
    codeBIN = dec2bin(hex2dec(codeHEX),16);     % initial binary stream
    pos_STQ = findstr(data_rover_all, codeBIN); % message initial index

    header1 = '3C';      % Fastrax header (hexadecimal value)
    header2 = '21';      % Fastrax header (hexadecimal value)
    codeHEX = [header1 header2];                % initial hexadecimal stream
    codeBIN = dec2bin(hex2dec(codeHEX),16);     % initial binary stream
    pos_FTX = findstr(data_rover_all, codeBIN); % message initial index
    
    header1 = '03';      % NVS footer (hexadecimal value)
    header2 = '10';      % NVS header (hexadecimal value)
    codeHEX = [header1 header2];                % initial hexadecimal stream
    codeBIN = dec2bin(hex2dec(codeHEX),16);     % initial binary stream
    pos_NVS = findstr(data_rover_all, codeBIN); % message initial index

    if ((length(pos_UBX) > length(pos_STQ)) && (length(pos_UBX) > length(pos_FTX)) && (length(pos_UBX) > length(pos_NVS)))
        
        receiver = 'u-blox';
        
        %UBX format decoding
        if (nargin == 5)
            [cell_rover] = decode_ublox(data_rover_all, constellations, wait_dlg);
        else
            [cell_rover] = decode_ublox(data_rover_all, constellations);
        end
    elseif ((length(pos_STQ) > length(pos_UBX)) && (length(pos_STQ) > length(pos_FTX)) && (length(pos_STQ) > length(pos_NVS)))
        
        receiver = 'SkyTraq';
        
        %SkyTraq format decoding
        if (nargin == 5)
            [cell_rover] = decode_skytraq(data_rover_all, constellations, wait_dlg);
        else
            [cell_rover] = decode_skytraq(data_rover_all, constellations);
        end
    elseif ((length(pos_FTX) > length(pos_UBX)) && (length(pos_FTX) > length(pos_STQ)) && (length(pos_FTX) > length(pos_NVS)))

        receiver = 'fastrax';
        
        %Fastrax format decoding
        if (nargin == 5)
            [cell_rover] = decode_fastrax_it03(data_rover_all, constellations, wait_dlg);
        else
            [cell_rover] = decode_fastrax_it03(data_rover_all, constellations);
        end
    elseif ((length(pos_NVS) > length(pos_UBX)) && (length(pos_NVS) > length(pos_STQ)) && (length(pos_NVS) > length(pos_FTX)))

        receiver = 'NVS';
        
        %compress <DLE><DLE> to <DLE>
        data_rover_all = reshape(data_rover_all,8,[]);
        data_rover_all = data_rover_all';
        data_rover_all = fbin2dec(data_rover_all);
        if (nargin == 5)
            data_rover_all = remove_double_10h(data_rover_all, wait_dlg);
        else
            data_rover_all = remove_double_10h(data_rover_all);
        end
        data_rover_all = dec2bin(data_rover_all,8);             %conversion in binary number (N x 8bits matrix)
        data_rover_all = data_rover_all';                       %transposed (8bits x N matrix)
        data_rover_all = data_rover_all(:)';                    %conversion into a string (8N bits vector)

        %NVS format decoding
        if (nargin == 5)
            [cell_rover] = decode_nvs(data_rover_all, constellations, wait_dlg);
        else
            [cell_rover] = decode_nvs(data_rover_all, constellations);
        end
    end
    clear data_rover_all

    %initialization (to make writing faster)
    Ncell  = size(cell_rover,2);                          %number of read UBX messages
    time_R = zeros(Ncell,1);                              %GPS time of week
    week_R = zeros(Ncell,1);                              %GPS week
    ph1_R  = zeros(nSatTot,Ncell);                        %phase observations
    pr1_R  = zeros(nSatTot,Ncell);                        %code observations
    dop1_R = zeros(nSatTot,Ncell);                        %doppler measurements
    snr_R  = zeros(nSatTot,Ncell);                        %signal-to-noise ratio
    lock_R = zeros(nSatTot,Ncell);                        %loss of lock indicator
    Eph_R  = zeros(33,nSatTot,Ncell);                     %broadcast ephemerides
    iono   = zeros(8,Ncell);                              %ionosphere parameters
    tick_TRACK  = zeros(Ncell,1);
    tick_PSEUDO = zeros(Ncell,1);
    phase_TRACK = zeros(nSatTot,Ncell);                   %phase observations - TRACK
    
    if (nargin == 5)
        waitbar(0,wait_dlg,'Reading rover data...')
    end
    
    %for Fastrax
    %                   L1 freq    RF_conv*MCLK      MixerOffeset
    correction_value = 1575420000 - 1574399750 - (3933/65536*16357400);
    correction_value = correction_value * (1575420000/(1+1574399750));
    doppler_count = 1;
    
    %for SkyTraq
    IOD_time = -1;
    
    i = 1;
    for j = 1 : Ncell
        if (nargin == 5)
            waitbar(j/Ncell,wait_dlg)
        end
        
        %%%%%%%%%%%%%%%%%%%%%% UBX messages %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        if (strcmp(cell_rover{1,j},'RXM-RAW'))            %RXM-RAW message data
            time_R(i)   = cell_rover{2,j}(1);
            week_R(i)   = cell_rover{2,j}(2);
            ph1_R(:,i)  = cell_rover{3,j}(:,1);
            pr1_R(:,i)  = cell_rover{3,j}(:,2);
            dop1_R(:,i) = cell_rover{3,j}(:,3);
            snr_R(:,i)  = cell_rover{3,j}(:,6);
            lock_R(:,i) = cell_rover{3,j}(:,7);
            
            %manage "nearly null" data
            ph1_R(abs(ph1_R(:,i)) < 1e-100,i) = 0;
            
            %keep just "on top of second" measurements
            %if (time_R(i)- floor(time_R(i)) == 0)
            i = i + 1;
            %end
            
        %RXM-SFRB message data save
        elseif (strcmp(cell_rover{1,j},'RXM-SFRB'))
            
            if (sum(cell_rover{2,j}(1:8)) ~= 0)
                %ionosphere parameters
                iono(:, i) = cell_rover{2,j}(1:8);
            end

        %RXM-EPH message data save
        elseif (strcmp(cell_rover{1,j},'RXM-EPH'))
            
            %satellite number
            sat = cell_rover{2,j}(1);
            toe = cell_rover{2,j}(18);                   %time of ephemeris
            
            %if the ephemerides are not already available
            if (~isempty(sat) & sat > 0 & isempty(find(Eph_R(18,sat,:) ==  toe, 1)))
                Eph_R(:,sat,i) = cell_rover{2,j}(:);     %single satellite ephemerides logging
                weekno = Eph_R(24,sat,i);
                Eph_R(32,sat,i) = weektime2tow(weekno,Eph_R(32,sat,i));
                Eph_R(33,sat,i) = weektime2tow(weekno,Eph_R(33,sat,i));
            end
            
        %AID-EPH message data save
        elseif (strcmp(cell_rover{1,j},'AID-EPH'))
            
            %satellite number
            sat = cell_rover{2,j}(1);
            toe = cell_rover{2,j}(18);                   %time of ephemeris

            %if the ephemerides are not already available
            if (~isempty(sat) & sat > 0 & isempty(find(Eph_R(18,sat,:) ==  toe, 1)))
                Eph_R(:,sat,i) = cell_rover{2,j}(:);     %single satellite ephemerides logging
                weekno = Eph_R(24,sat,i);
                Eph_R(32,sat,i) = weektime2tow(weekno,Eph_R(32,sat,i));
                Eph_R(33,sat,i) = weektime2tow(weekno,Eph_R(33,sat,i));
            end
            
        %AID-HUI message data save
        elseif (strcmp(cell_rover{1,j},'AID-HUI'))

            %ionosphere parameters
            iono(:, i) = cell_rover{3,j}(9:16);
            
        %%%%%%%%%%%%%%%%%% SkyTraq messages %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        %MEAS_TIME message data save
        elseif (strcmp(cell_rover{1,j},'MEAS_TIME'))

            IOD_time = cell_rover{2,j}(1);
            time_stq = cell_rover{2,j}(3);
            week_stq = cell_rover{2,j}(2);
            
        %RAW_MEAS message data save
        elseif (strcmp(cell_rover{1,j},'RAW_MEAS'))

            IOD_raw = cell_rover{2,j}(1);
            if (IOD_raw == IOD_time)
                time_R(i)  = time_stq;
                week_R(i)  = week_stq;
                pr1_R(:,i) = cell_rover{3,j}(:,3);
                ph1_R(:,i) = cell_rover{3,j}(:,4);
                snr_R(:,i) = cell_rover{3,j}(:,2);
                dop1_R(:,i) = cell_rover{3,j}(:,5);

                %manage "nearly null" data
                pr1_R(abs(pr1_R(:,i)) < 1e-100,i) = 0;
                ph1_R(abs(ph1_R(:,i)) < 1e-100,i) = 0;
                
                %manage phase without code
                ph1_R(abs(pr1_R(:,i)) == 0,i) = 0;

                i = i + 1;
            end
            
        %GPS Ephemeris data message data save
        elseif (strcmp(cell_rover{1,j},'GPS_EPH'))
            
            %satellite number
            sat = cell_rover{2,j}(1);
            toe = cell_rover{2,j}(18);                   %time of ephemeris
            
            %if the ephemerides are not already available
            if (~isempty(sat) & sat > 0 & isempty(find(Eph_R(18,sat,:) ==  toe, 1)))
                Eph_R(:,sat,i) = cell_rover{2,j}(:);     %single satellite ephemerides logging
                weekno = Eph_R(24,sat,i);
                Eph_R(32,sat,i) = weektime2tow(weekno,Eph_R(32,sat,i));
                Eph_R(33,sat,i) = weektime2tow(weekno,Eph_R(33,sat,i));
            end

        %%%%%%%%%%%%%%%%%%%%%% FTX messages %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%            
        %TRACK message
        elseif (strcmp(cell_rover{1,j},'TRACK'))
            tick_TRACK(i)    = cell_rover{2,j}(1);
            phase_TRACK(:,i) = cell_rover{3,j}(:,6);

        %PSEUDO message data save
        elseif (strcmp(cell_rover{1,j},'PSEUDO'))
            time_R(i)   = cell_rover{2,j}(1);
            week_R(i)   = cell_rover{2,j}(2);
            ph1_R(:,i)  = cell_rover{3,j}(:,1);
            pr1_R(:,i)  = cell_rover{3,j}(:,2);
            dop1_R(:,i) = cell_rover{3,j}(:,3);
            snr_R(:,i)  = cell_rover{3,j}(:,6);
            
            tick_PSEUDO(i) = cell_rover{2,j}(4);
            
            if (tick_PSEUDO(i) == tick_TRACK(i))
                %phase correction
                ph1_R(:,i) = phase_TRACK(:,i) - correction_value*doppler_count;
                doppler_count = doppler_count + 1;
            else
                ph1_R(:,i) = 0;
            end

            %manage phase without code
            ph1_R(abs(pr1_R(:,i)) == 0,i) = 0;
            
            %manage "nearly null" data
            ph1_R(abs(ph1_R(:,i)) < 1e-100,i) = 0;

            i = i + 1;

            %iono(:, i) = iono(:, i-1);              %previous epoch iono parameters copying            
            
        %FTX-EPH message data save
        elseif (strcmp(cell_rover{1,j},'FTX-EPH'))
            
            %satellite number
            sat = cell_rover{2,j}(1);
            toe = cell_rover{2,j}(18);                   %time of ephemeris

            %if the ephemerides are not already available
            if (~isempty(sat) & sat > 0 & isempty(find(Eph_R(18,sat,:) ==  toe, 1)))
                Eph_R(:,sat,i) = cell_rover{2,j}(:);     %single satellite ephemerides logging
                weekno = Eph_R(24,sat,i);
                Eph_R(32,sat,i) = weektime2tow(weekno,Eph_R(32,sat,i));
                Eph_R(33,sat,i) = weektime2tow(weekno,Eph_R(33,sat,i));
            end
            
        %%%%%%%%%%%%%%%%%%%%%% NVS messages %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        elseif (strcmp(cell_rover{1,j},'F5h'))            %F5h message data
            time_R(i)   = cell_rover{2,j}(1);
            week_R(i)   = cell_rover{2,j}(2)+1024;
            ph1_R(:,i)  = cell_rover{3,j}(:,1);
            pr1_R(:,i)  = cell_rover{3,j}(:,2);
            dop1_R(:,i) = cell_rover{3,j}(:,3);
            snr_R(:,i)  = cell_rover{3,j}(:,6);
            
            %manage "nearly null" data
            ph1_R(abs(ph1_R(:,i)) < 1e-100,i) = 0;
            
            %keep just "on top of second" measurements
            %if (time_R(i)- floor(time_R(i)) == 0)
            i = i + 1;
            %end
            
        %62h message data save
        elseif (strcmp(cell_rover{1,j},'62h'))
            
            %satellite number
            sat = cell_rover{2,j}(1);
            toe = cell_rover{2,j}(18);                   %time of ephemeris
            
            %if the ephemerides are not already available
            if (~isempty(sat) & sat > 0 & isempty(find(Eph_R(18,sat,:) ==  toe, 1)))
                Eph_R(:,sat,i) = cell_rover{2,j}(:);     %single satellite ephemerides logging
                weekno = Eph_R(24,sat,i);
                Eph_R(32,sat,i) = weektime2tow(weekno,Eph_R(32,sat,i));
                Eph_R(33,sat,i) = weektime2tow(weekno,Eph_R(33,sat,i));
            end

        %F7h message data save
        elseif (strcmp(cell_rover{1,j},'F7h'))
            
            %satellite number
            sat = cell_rover{2,j}(1);
            toe = cell_rover{2,j}(18);                   %time of ephemeris
            
            %if the ephemerides are not already available
            if (~isempty(sat) & sat > 0 & isempty(find(Eph_R(18,sat,:) ==  toe, 1)))
                Eph_R(:,sat,i) = cell_rover{2,j}(:);     %single satellite ephemerides logging
                weekno = Eph_R(24,sat,i);
                Eph_R(32,sat,i) = weektime2tow(weekno,Eph_R(32,sat,i));
                Eph_R(33,sat,i) = weektime2tow(weekno,Eph_R(33,sat,i));
            end
            
        %4Ah message data save
        elseif (strcmp(cell_rover{1,j},'4Ah'))

            %ionosphere parameters
            iono(:, i) = cell_rover{2,j}(1:8);

        end
    end
    clear cell_rover
    clear Ncell pos sat toe

    %residual data erase (after initialization)
    time_R(i:end)    = [];
    week_R(i:end)    = [];
    ph1_R(:,i:end)   = [];
    pr1_R(:,i:end)   = [];
    dop1_R(:,i:end)  = [];
    snr_R(:,i:end)   = [];
    lock_R(:,i:end)  = [];
    Eph_R(:,:,i:end) = [];
    iono(:,i:end)    = [];

    if (~isempty(time_R))
        %date decoding
        date = gps2date(week_R, time_R);
    else
        %displaying
        if (nargin == 5)
            msgbox('No raw data acquired.');
        else
            fprintf('No raw data acquired.\n');
        end
        
        return
    end
    
    %----------------------------------------------------------------------------------------------
    % APPROXIMATE POSITION
    %----------------------------------------------------------------------------------------------
 
    pos_R = zeros(3,1);
    
    %if ephemerides are available
    if (~isempty(find(Eph_R(1,:,:) ~= 0, 1)))
        cutoff = 15;
        snr_threshold = 0;
        weights = 0;
        i = 1;
        %try to compute an approximate position; if still no luck by the 100th epoch
        %(or by the total number of available epochs, whichever comes first), give up
        epoch_limit = min(length(time_R), 100);
        while (sum(abs((pos_R))) == 0 & i <= epoch_limit)
            satObs = find(pr1_R(:,i) ~= 0);
            nsat = length(satObs);
            Eph_t = rt_find_eph (Eph_R, time_R(i), nsat);
            satEph = find(Eph_t(1,:) ~= 0);
            satAvail = intersect(satObs,satEph)';
            if (length(satAvail) >=4)
                pos_R = init_positioning(time_R(i), pr1_R(satAvail,i), snr_R(satAvail,i), Eph_t(:,:), [], iono(:,i), [], [], [], [], satAvail, cutoff, snr_threshold, 0, 0);
            end
            i = i + 1;
        end
    end
    
    %----------------------------------------------------------------------------------------------
    % OBSERVATION RATE (INTERVAL)
    %----------------------------------------------------------------------------------------------
    
    interval = median(time_R(2:end) - time_R(1:end-1));
    
    %----------------------------------------------------------------------------------------------
    % MULTI-CONSTELLATION SETTINGS
    %----------------------------------------------------------------------------------------------
    
    GPSenabled = constellations.GPS.enabled;
    GLOenabled = constellations.GLONASS.enabled;
    GALenabled = constellations.Galileo.enabled;
    BDSenabled = constellations.BeiDou.enabled;
    QZSenabled = constellations.QZSS.enabled;
    SBSenabled = constellations.SBAS.enabled;
    
    if (GPSenabled), GPSavailable = any(any(pr1_R(constellations.GPS.indexes,:))); else GPSavailable = 0; end
    if (GLOenabled), GLOavailable = any(any(pr1_R(constellations.GLONASS.indexes,:))); else GLOavailable = 0; end
    if (GALenabled), GALavailable = any(any(pr1_R(constellations.Galileo.indexes,:))); else GALavailable = 0; end
    if (BDSenabled), BDSavailable = any(any(pr1_R(constellations.BeiDou.indexes,:))); else BDSavailable = 0; end
    if (QZSenabled), QZSavailable = any(any(pr1_R(constellations.QZSS.indexes,:))); else QZSavailable = 0; end
    if (SBSenabled), SBSavailable = any(any(pr1_R(constellations.SBAS.indexes,:))); else SBSavailable = 0; end
    
    i = 1;
    if (GPSenabled && ~GPSavailable), warning_msg{i} = 'GPS observations not available'; i = i + 1; end
    if (GLOenabled && ~GLOavailable), warning_msg{i} = 'GLONASS observations not available'; i = i + 1; end
    if (GALenabled && ~GALavailable), warning_msg{i} = 'Galileo observations not available'; i = i + 1; end
    if (BDSenabled && ~BDSavailable), warning_msg{i} = 'BeiDou observations not available'; i = i + 1; end
    if (QZSenabled && ~QZSavailable), warning_msg{i} = 'QZSS observations not available'; i = i + 1; end
    if (SBSenabled && ~SBSavailable), warning_msg{i} = 'SBAS observations not available'; i = i + 1; end
    
    if (i > 1)
        if (nargin == 5)
            msgbox(warning_msg);
        else
            for j = 1 : (i-1); fprintf(['WARNING: ' warning_msg{j} '.\n']); end
        end
    end
    
    GPSactive = (GPSenabled && GPSavailable);
    GLOactive = (GLOenabled && GLOavailable);
    GALactive = (GALenabled && GALavailable);
    BDSactive = (BDSenabled && BDSavailable);
    QZSactive = (QZSenabled && QZSavailable);
    SBSactive = (SBSenabled && SBSavailable);
    
    SYSactive = [GPSactive, GLOactive, GALactive, ...
                 BDSactive, QZSactive, SBSactive];

    mixed_sys  = (sum(SYSactive) >= 2);
    single_sys = (sum(SYSactive) == 1);
    
    %----------------------------------------------------------------------------------------------
    % RINEX OBSERVATION FILE
    %----------------------------------------------------------------------------------------------
    
    %displaying
    if (nargin == 4)
        fprintf(['Writing: ' filename '.obs\n']);
    end
    
    %create RINEX observation file
    fid_obs = fopen([filename '.obs'],'wt');
    
    %file type
    if (mixed_sys)
        file_type = 'M (MIXED)';
    elseif(single_sys && GPSactive)
        file_type = 'G (GPS)';
    elseif(single_sys && GLOactive)
        file_type = 'R (GLONASS)';
    elseif(single_sys && GALactive)
        file_type = 'E (GALILEO)';
    elseif(single_sys && SBSactive)
        file_type = 'S (SBAS PAYLOAD)';
    end
    
    %current date and time in UTC
    date_str_UTC = local_time_to_utc(now, 30);
    [date_str_UTC, time_str_UTC] = strtok(date_str_UTC,'T');
    time_str_UTC = time_str_UTC(2:end-1);
    
    %maximum filename length for RUN BY field
    rb_len = min(20,length(rinex_metadata.agency));
    
    %maximum filename length for MARKER NAME field
    mn_len = min(60,length(rinex_metadata.marker_name));
    
    %maximum filename length for OBSERVER field
    ob_len = min(20,length(rinex_metadata.observer));
    
    %maximum filename length for AGENCY field
    oa_len = min(40,length(rinex_metadata.observer_agency));
    
    %system id
    sys = [];
    band = [];
    attrib = [];
    if (GPSactive), sys = [sys 'G']; band = [band '1']; attrib = [attrib 'C']; end
    if (GLOactive), sys = [sys 'R']; band = [band '1']; attrib = [attrib 'C']; end
    if (GALactive), sys = [sys 'E']; band = [band '1']; attrib = [attrib 'X']; end
    if (BDSactive), sys = [sys 'C']; band = [band '2']; attrib = [attrib 'I']; end
    if (QZSactive), sys = [sys 'J']; band = [band '1']; attrib = [attrib 'C']; end
    if (SBSactive), sys = [sys 'S']; band = [band '1']; attrib = [attrib 'C']; end

    %write header
    fprintf(fid_obs,'%9.2f           OBSERVATION DATA    %-19s RINEX VERSION / TYPE\n', str2num(rinex_metadata.version), file_type);
    fprintf(fid_obs,'%-20s%-20s%-20sPGM / RUN BY / DATE \n', 'goGPS', rinex_metadata.agency(1:rb_len), [date_str_UTC ' ' time_str_UTC ' UTC']);
    fprintf(fid_obs,'%-60sMARKER NAME         \n',rinex_metadata.marker_name(1:mn_len));
    if (rin_ver_id == 3)
        fprintf(fid_obs,'%-20s                                        MARKER TYPE         \n', rinex_metadata.marker_type);
    end
    fprintf(fid_obs,'%-20s%-40sOBSERVER / AGENCY   \n', rinex_metadata.observer(1:ob_len), rinex_metadata.observer_agency(1:oa_len));
    fprintf(fid_obs,'                    %-20s                    REC # / TYPE / VERS \n', receiver);
    fprintf(fid_obs,'                                                            ANT # / TYPE        \n');
    fprintf(fid_obs,'%14.4f%14.4f%14.4f                  APPROX POSITION XYZ \n', pos_R(1), pos_R(2), pos_R(3));
    fprintf(fid_obs,'        0.0000        0.0000        0.0000                  ANTENNA: DELTA H/E/N\n');
    fprintf(fid_obs,'     2     0                                                WAVELENGTH FACT L1/2\n');
    if (rin_ver_id == 2)
        fprintf(fid_obs,'     4    C1    L1    S1    D1                              # / TYPES OF OBSERV \n');
    else
        for s = 1 : length(sys)
            fprintf(fid_obs,'%-1s    4 C%c%c L%c%c S%c%c D%c%c                                      SYS / # / OBS TYPES \n',sys(s),band(s),attrib(s),band(s),attrib(s),band(s),attrib(s),band(s),attrib(s));
        end
        fprintf(fid_obs,'DBHZ                                                        SIGNAL STRENGTH UNIT\n');
    end
    fprintf(fid_obs,'%10.3f                                                  INTERVAL            \n', interval);
    fprintf(fid_obs,'%6d%6d%6d%6d%6d%13.7f     GPS         TIME OF FIRST OBS   \n', ...
        date(1,1), date(1,2), date(1,3), date(1,4), date(1,5), date(1,6));
    if (rin_ver_id == 3)
        for s = 1 : length(sys)
            fprintf(fid_obs,'%c                                                           SYS / PHASE SHIFTS  \n',sys(s));
        end
    end
    fprintf(fid_obs,'                                                            END OF HEADER       \n');
    
    %-------------------------------------------------------------------------------
    
    %number of records
    N = length(time_R);
    
    if (nargin == 5)
        waitbar(0,wait_dlg,'Writing rover observation file...')
    end
    
    date(:,1) = two_digit_year(date(:,1));
    
    %cycle through epochs
    for i = 1 : N
        if (nargin == 5)
            waitbar(i/N,wait_dlg)
        end

        sat = find(pr1_R(:,i) ~= 0);
        n = length(sat);
        
        %assign system and PRN code to each satellite
        [sys, prn] = find_sat_system(sat, constellations);

        %if no observations are available, do not write anything
        if (n > 0)
            
            if (i > 1)
                current_epoch = datenum([date(i,1), date(i,2), date(i,3), date(i,4), date(i,5), date(i,6)]);
                if (current_epoch == previous_epoch)
                    continue %some binary streams contained the same epoch twice (some kind of bug...)
                end
            end
            
            previous_epoch = datenum([date(i,1), date(i,2), date(i,3), date(i,4), date(i,5), date(i,6)]);
            
            %RINEX v2.xx
            if (rin_ver_id == 2)
                %epoch record
                fprintf(fid_obs,' %02d %2d %2d %2d %2d %10.7f  0 %2d', ...
                    date(i,1), date(i,2), date(i,3), date(i,4), date(i,5), date(i,6), n);
                if (n>12)
                    for j = 1 : 12
                        fprintf(fid_obs,'%c%02d',sys(j),prn(j));
                    end
                    fprintf(fid_obs,'\n');
                    fprintf(fid_obs,'%32s','');
                    for j = 13 : n
                        fprintf(fid_obs,'%c%02d',sys(j),prn(j));
                    end
                else
                    for j = 1 : n
                        fprintf(fid_obs,'%c%02d',sys(j),prn(j));
                    end
                end
                fprintf(fid_obs,'\n');
                %observation record(s)
                for j = 1 : n
                    fprintf(fid_obs,'%14.3f %1d',pr1_R(sat(j),i),floor(snr_R(sat(j),i)/6));
                    if (abs(ph1_R(sat(j),i)) > 1e-100)
                        fprintf(fid_obs,'%14.3f%1d%1d',ph1_R(sat(j),i),lock_R(sat(j),i),floor(snr_R(sat(j),i)/6));
                    else
                        fprintf(fid_obs,'                ');
                    end
                    fprintf(fid_obs,'%14.3f %1d',snr_R(sat(j),i),floor(snr_R(sat(j),i)/6));
                    fprintf(fid_obs,'%14.3f %1d',dop1_R(sat(j),i),floor(snr_R(sat(j),i)/6));
                    fprintf(fid_obs,'\n');
                end
            %RINEX v3.xx    
            else
                %epoch record
                fprintf(fid_obs,'> %4d %2d %2d %2d %2d %10.7f  0 %2d\n', ...
                    four_digit_year(date(i,1)), date(i,2), date(i,3), date(i,4), date(i,5), date(i,6), n);
                %observation record(s)
                for j = 1 : n
                    fprintf(fid_obs,'%c%02d',sys(j),prn(j));
                    fprintf(fid_obs,'%14.3f %1d',pr1_R(sat(j),i),floor(snr_R(sat(j),i)/6));
                    if (abs(ph1_R(sat(j),i)) > 1e-100)
                        fprintf(fid_obs,'%14.3f%1d%1d',ph1_R(sat(j),i),lock_R(sat(j),i),floor(snr_R(sat(j),i)/6));
                    else
                        fprintf(fid_obs,'                ');
                    end
                    fprintf(fid_obs,'%14.3f %1d',snr_R(sat(j),i),floor(snr_R(sat(j),i)/6));
                    fprintf(fid_obs,'%14.3f %1d',dop1_R(sat(j),i),floor(snr_R(sat(j),i)/6));
                    fprintf(fid_obs,'\n');
                end
            end
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
        if (nargin == 4)
            fprintf(['Writing: ' filename '.nav\n']);
        end
        
        if (nargin == 5)
            waitbar(0,wait_dlg,'Writing rover navigation file...')
        end

        ext = [];
        if (rin_ver_id == 2)
            sat_sys = cell(0);
            m = 1;
            if (GPSactive), sat_sys{m} = 'G (GPS)';     m = m + 1; ext = [ext 'n']; end
            if (GLOactive), sat_sys{m} = 'R (GLONASS)'; m = m + 1; ext = [ext 'g']; end
            if (GALactive), sat_sys{m} = 'E (GALILEO)';            ext = [ext 'l']; end
        else
            if (mixed_sys)
                ext = 'p';
            elseif(single_sys && GPSactive)
                ext = 'n';
            elseif(single_sys && GLOactive)
                ext = 'g';
            elseif(single_sys && GALactive)
                ext = 'l';
            end
            sat_sys{1} = file_type;
        end

        for f = 1 : length(ext)
            
            %create RINEX navigation file
            fid_nav = fopen([filename sprintf('.%2d%c', date(1,1), ext)], 'wt');

            %write header
            if (rin_ver_id == 2)
                fprintf(fid_nav,'%9.2f           NAVIGATION DATA                         RINEX VERSION / TYPE\n', str2num(rinex_metadata.version));
            else
                fprintf(fid_nav,'%9.2f           NAVIGATION DATA     %-20sRINEX VERSION / TYPE\n', str2num(rinex_metadata.version), sat_sys{f});
            end
            fprintf(fid_nav,'%-20s%-20s%-20sPGM / RUN BY / DATE \n', 'goGPS', rinex_metadata.agency(1:rb_len), [date_str_UTC ' ' time_str_UTC ' UTC']);
            
            %find first non-zero ionosphere parameters
            pos = find(iono(1,:) ~= 0);
            if (~isempty(pos))
                iono = iono(:,pos(1));
            end
            
            if (~isempty(pos))
                if (~isunix)
                    line_alphaE = sprintf('%13.4E%13.4E%13.4E%13.4E', iono(1), iono(2), iono(3), iono(4));
                    line_betaE  = sprintf('%13.4E%13.4E%13.4E%13.4E', iono(5), iono(6), iono(7), iono(8));
                else
                    line_alphaE = sprintf('%12.4E%12.4E%12.4E%12.4E', iono(1), iono(2), iono(3), iono(4));
                    line_betaE  = sprintf('%12.4E%12.4E%12.4E%12.4E', iono(5), iono(6), iono(7), iono(8));
                end
                %if running on Windows, convert three-digits exponential notation
                %to two-digits; in any case, replace 'E' with 'D' and print the string
                if (~isunix)
                    line_alphaD = strrep(line_alphaE(1,:),'E+0','D+');
                    line_alphaD = strrep(line_alphaD,'E-0','D-');
                    line_betaD = strrep(line_betaE(1,:),'E+0','D+');
                    line_betaD = strrep(line_betaD,'E-0','D-');
                else
                    line_alphaD = strrep(line_alphaE(1,:),'E+','D+');
                    line_alphaD = strrep(line_alphaD,'E-','D-');
                    line_betaD = strrep(line_betaE(1,:),'E+','D+');
                    line_betaD = strrep(line_betaD,'E-','D-');
                end
                
                if (rin_ver_id == 2)
                    fprintf(fid_nav,'  %s          ION ALPHA           \n',line_alphaD);
                    fprintf(fid_nav,'  %s          ION BETA            \n',line_betaD);
                else
                    fprintf(fid_nav,'GPSA %s       IONOSPHERIC CORR    \n',line_alphaD);
                    fprintf(fid_nav,'GPSB %s       IONOSPHERIC CORR    \n',line_betaD);
                end
            end
            fprintf(fid_nav,'                                                            END OF HEADER       \n');
            
            for i = 1 : N
                if (nargin == 5)
                    waitbar(i/N,wait_dlg)
                end
                
                satEph = find(Eph_R(1,:,i) ~= 0);
                for j = 1 : length(satEph)
                    %if not GLONASS
                    if (~strcmp(Eph_R(31,satEph(j),i),'R'))

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
                        toc      = Eph_R(21,satEph(j),i);
                        IODE     = Eph_R(22,satEph(j),i);
                        codes    = Eph_R(23,satEph(j),i);
                        weekno   = Eph_R(24,satEph(j),i); %#ok<NASGU>
                        L2flag   = Eph_R(25,satEph(j),i);
                        svaccur  = Eph_R(26,satEph(j),i);
                        svhealth = Eph_R(27,satEph(j),i);
                        tgd      = Eph_R(28,satEph(j),i);
                        fit_int  = Eph_R(29,satEph(j),i);
                        
                        %time of measurement decoding
                        date = gps2date(week_R(i), toc);
                        date(1) = two_digit_year(date(1));
                        
                        lineE(1,:) = sprintf('%2d %02d %2d %2d %2d %2d%5.1f% 18.12E% 18.12E% 18.12E\n', ...
                            satEph(j),date(1), date(2), date(3), date(4), date(5), date(6), ...
                            af0, af1, af2);
                        linesE(1,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', IODE , crs, deltan, M0);
                        linesE(2,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', cuc, ecc, cus, roota);
                        linesE(3,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', toe, cic, Omega0, cis);
                        linesE(4,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', i0, crc, omega, Omegadot);
                        linesE(5,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', idot, codes, week_R(1), L2flag);
                        linesE(6,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', svaccur, svhealth, tgd, IODE);
                        linesE(7,:) = sprintf('   % 18.12E% 18.12E% 18.12E% 18.12E\n', toc, fit_int, 0, 0);  %here "toc" should be "tom" (e.g. derived from Z-count in Hand Over Word)
                    %if GLONASS
                    else
                        TauN     = Eph_R(2,satEph(j),i);
                        GammaN   = Eph_R(3,satEph(j),i);
                        tk       = Eph_R(4,satEph(j),i);
                        X        = Eph_R(5,satEph(j),i)/1e3;  %satellite X coordinate at ephemeris reference time [km]
                        Y        = Eph_R(6,satEph(j),i)/1e3;  %satellite Y coordinate at ephemeris reference time [km]
                        Z        = Eph_R(7,satEph(j),i)/1e3;  %satellite Z coordinate at ephemeris reference time [km]
                        Xv       = Eph_R(8,satEph(j),i)/1e3;  %satellite velocity along X at ephemeris reference time [m/s]
                        Yv       = Eph_R(9,satEph(j),i)/1e3;  %satellite velocity along Y at ephemeris reference time [m/s]
                        Zv       = Eph_R(10,satEph(j),i)/1e3; %satellite velocity along Z at ephemeris reference time [m/s]
                        Xa       = Eph_R(11,satEph(j),i)/1e3; %acceleration due to lunar-solar gravitational perturbation along X at ephemeris reference time [m/s^2]
                        Ya       = Eph_R(12,satEph(j),i)/1e3; %acceleration due to lunar-solar gravitational perturbation along Y at ephemeris reference time [m/s^2]
                        Za       = Eph_R(13,satEph(j),i)/1e3; %acceleration due to lunar-solar gravitational perturbation along Z at ephemeris reference time [m/s^2]
                        E        = Eph_R(14,satEph(j),i);
                        freq_num = Eph_R(15,satEph(j),i);
                        toe      = Eph_R(18,satEph(j),i);
                        week_toe = Eph_R(24,satEph(j),i);
                        Bn       = Eph_R(27,satEph(j),i); %health flag
                        
                        %time of measurement decoding
                        date = gps2date(week_toe, toe);
                        date(1) = two_digit_year(date(1));
                        
                        %TO BE CONTINUED...
                        
                    end
                    
                    %if running on Windows, convert three-digits exponential notation
                    %to two-digits; in any case, replace 'E' with 'D' and print the string
                    n = size(linesE,1);
                    if (~isunix)
                        lineD = strrep(lineE(1,:),'E+0','D+');
                        lineD = strrep(lineD,'E-0','D-');
                        fprintf(fid_nav,'%s',lineD);
                        for k = 1 : n
                            lineD = strrep(linesE(k,:),'E+0','D+');
                            lineD = strrep(lineD,'E-0','D-');
                            fprintf(fid_nav,'%s',lineD);
                        end
                    else
                        lineD = strrep(lineE(1,:),'E+','D+');
                        lineD = strrep(lineD,'E-','D-');
                        fprintf(fid_nav,'%s',lineD);
                        for k = 1 : n
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
    end
    
    %output week number
    if (~isempty(week_R))
        week = week_R(1);
    end
else
    %displaying
    if (nargin == 5)
        msgbox('No rover data acquired.');
    else
        fprintf('No rover data acquired.\n');
    end
end