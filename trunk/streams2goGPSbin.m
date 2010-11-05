function streams2goGPSbin(filerootIN, filerootOUT, wait_dlg)

% SYNTAX:
%   streams2goGPSbin(filerootIN, filerootOUT, wait_dlg);
%
% INPUT:
%   filerootIN  = input file root
%   filerootOUT = output file root
%   wait_dlg = optional handler to waitbar figure
%
% OUTPUT:
%
% DESCRIPTION:
%   File conversion from rover and master streams (UBX binary) and
%   (RTCM 3.x) respectively to goGPS binary format (*_obs_* and *_eph_*
%   files).

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1.3 alpha
%
% Copyright (C) 2009-2010 Mirko Reguzzoni, Eugenio Realini
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

%ROVER and MASTER stream reading
if (nargin == 3)
    [time_GPS, week_R, time_R, time_M, pr1_R, pr1_M, ph1_R, ph1_M, snr_R, snr_M, pos_M, Eph, ...
        iono, loss_R, loss_M, data_rover_all, data_master_all, nmea_sentences] = load_stream(filerootIN, wait_dlg); %#ok<*ASGLU>
else
    [time_GPS, week_R, time_R, time_M, pr1_R, pr1_M, ph1_R, ph1_M, snr_R, snr_M, pos_M, Eph, ...
        iono, loss_R, loss_M, data_rover_all, data_master_all, nmea_sentences] = load_stream(filerootIN);
end

if (~isempty(Eph))

    EphAvailable = find(Eph(1,:,:)~=0, 1);

    if ~isempty(data_master_all)
        satObs = find((pr1_R(:,1) ~= 0) & (pr1_M(:,1) ~= 0));
    else
        satObs = find(pr1_R(:,1) ~= 0);
    end

    %if the dataset has ephemerides available at least for one epoch
    if (~isempty(EphAvailable))
        satEph = find(sum(abs(Eph(:,:,1)))~=0);
        while (length(satEph) < length(satObs)) | (length(satObs) < 4)
            
            time_GPS(1) = [];
            week_R(1)   = [];
            time_R(1)   = [];
            time_M(1)   = [];
            pr1_R(:,1)  = [];
            pr1_M(:,1)  = [];
            ph1_R(:,1)  = [];
            ph1_M(:,1)  = [];
            snr_R(:,1)  = [];
            snr_M(:,1)  = [];
            pos_M(:,1)  = [];
            Eph(:,:,1)  = [];
            iono(:,1)   = [];
            loss_R(1)   = [];
            loss_M(1)   = [];
            
            if ~isempty(data_master_all)
                satObs = find((pr1_R(:,1) ~= 0) & (pr1_M(:,1) ~= 0));
            else
                satObs = find(pr1_R(:,1) ~= 0);
            end
            satEph = find(sum(abs(Eph(:,:,1)))~=0);
        end
        
        %remove observations without ephemerides
        for i = 1 : length(time_GPS)
            satEph = find(sum(abs(Eph(:,:,i)))~=0);
            delsat = setdiff(1:32,satEph);
            pr1_R(delsat,i) = 0;
            pr1_M(delsat,i) = 0;
            ph1_R(delsat,i) = 0;
            ph1_M(delsat,i) = 0;
            snr_R(delsat,i) = 0;
            snr_M(delsat,i) = 0;
        end
    else
        if (nargin == 3)
            msgbox('Warning: this dataset does not contain ephemerides!');
        else
            fprintf('Warning: this dataset does not contain ephemerides!\n');
        end
    end 
end

%complete/partial path
tMin = 1;
tMax = 1e30;
tMin = max(tMin,1);
tMax = min(tMax,length(time_GPS));
time_GPS = time_GPS(tMin:tMax);
week_R = week_R(tMin:tMax);
time_R = time_R(tMin:tMax);
time_M = time_M(tMin:tMax);
pr1_R = pr1_R(:,tMin:tMax);
pr1_M = pr1_M(:,tMin:tMax);
ph1_R = ph1_R(:,tMin:tMax);
ph1_M = ph1_M(:,tMin:tMax);
snr_R = snr_R(:,tMin:tMax);
snr_M = snr_M(:,tMin:tMax);
pos_M = pos_M(:,tMin:tMax);
Eph = Eph(:,:,tMin:tMax);
iono = iono(:,tMin:tMax);

%do not overwrite existing files
i = 1;
j = length(filerootOUT);
while (~isempty(dir([filerootOUT '_obs*.bin'])) | ...
        ~isempty(dir([filerootOUT '_eph*.bin'])) )
    
    filerootOUT(j+1:j+3) = ['_' num2str(i,'%02d')];
    i = i + 1;
end

%open output files
fid_obs = fopen([filerootOUT '_obs_00.bin'],'w+');
if (~isempty(EphAvailable))
    fid_eph = fopen([filerootOUT '_eph_00.bin'],'w+');
end

%"file hour" variable
hour = 0;

if (nargin == 3)
    waitbar(0,wait_dlg,'Writing goGPS binary data...')
end

%write output files
for t = 1 : length(time_GPS)
    
    if (nargin == 3)
        waitbar(t/length(time_GPS),wait_dlg)
    end
    
    %-------------------------------------
    % file management
    %-------------------------------------
    
    if (floor(t/3600) > hour)
        
        hour = floor(t/3600);
        hour_str = num2str(hour,'%02d');
        
        fclose(fid_obs);
        if (~isempty(EphAvailable))
            fclose(fid_eph);
        end
        
        fid_obs    = fopen([filerootOUT '_obs_'    hour_str '.bin'],'w+');
        if (~isempty(EphAvailable))
            fid_eph    = fopen([filerootOUT '_eph_'    hour_str '.bin'],'w+');
        end
        
    end
    
    fwrite(fid_obs, [time_GPS(t); time_M(t); time_R(t); week_R(t); pr1_M(:,t); pr1_R(:,t); ph1_M(:,t); ph1_R(:,t); snr_M(:,t); snr_R(:,t); pos_M(:,t); iono(:,t)], 'double');
    if (~isempty(EphAvailable))
        Eph_t = Eph(:,:,t);
        fwrite(fid_eph, [time_GPS(t); Eph_t(:)], 'double');
    end
end

if (~isempty(nmea_sentences))
    fid_nmea = fopen([filerootOUT '_ublox_NMEA.txt'],'wt');
    n = size(nmea_sentences,1);
    for i = 1 : n
        fprintf(fid_nmea, '%s', char(nmea_sentences(i,1)));
    end
    fclose(fid_nmea);
end

%close files
fclose(fid_obs);
if (~isempty(EphAvailable))
    fclose(fid_eph);
end