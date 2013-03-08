%   OBJECT goGNSS
% =========================================================================
%
% DESCRIPTION
%   Object to manage a useful functions / standard parameters of goGPS
%   Under development no methods are used up to now...
%
% EXAMPLE
%   go = goGNSS();
%
% FOR A LIST OF CONSTANTs and METHODS use doc goGNSS
%
%----------------------------------------------------------------------------------------------
% Copyright (C) 2009-2013 Mirko Reguzzoni, Eugenio Realini
%----------------------------------------------------------------------------------------------
%
%    Code contributed by Stefano Caldera, Andrea Gatti, Lisa Pertusini
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
%---------------------------------------------------------------------------------------------

classdef goGNSS < handle
    
    % Constant values
    % => to discriminate them from function (in autocompletition) they are
    % written in capital letters
    properties (Constant)
        % GENERIC CONSTANTS -----------------------------------------------
        
        V_LIGHT = 299792458;                  % velocity of light in the void [m/s]
        
        ELL_A = 6378137;                      % Ellipsoid semi-major axis [m]
        ELL_F = 1/298.257222101;              % Ellipsoid flattening
        ELL_E = sqrt(1-(1-goGNSS.ELL_F)^2);   % Eccentricity
        
        OMEGAE_DOT = 7.2921151467e-5;         % Angular velocity of the Earth rotation [rad/s]
        GM = 3.986004418e14;                  % Gravitational constant * (mass of Earth) [m^3/s^2]
        
        MAX_SAT      = 32                     % Maximum number of active satellites in a constellation
        
        % CONSTELLATION SPECIFIC ------------------------------------------
        
        FG = [1575.420 1227.600]*1e6;         % GPS carriers frequencies [Hz]
        LAMBDAG = goGNSS.V_LIGHT ./ goGNSS.FG;% GPS carriers wavelengths [m]
        
        % CONSTELLATIONS IDs ----------------------------------------------
        
        ID_GPS     = 1 % Id of GPS constellation for goGPS internal use
        ID_GLONASS = 2 % Id of GLONASS constellation for goGPS internal use
        ID_GALILEO = 3 % Id of Galileo constellation for goGPS internal use
        ID_BEIDOU  = 4 % Id of BeiDou constellation for goGPS internal use
        ID_QZSS    = 5 % Id of QZSS constellation for goGPS internal use
        ID_SBAS    = 6 % Id of SBAS constellation for goGPS internal use
        
        % goGPS MODES -----------------------------------------------------
        
        MODE_RT_NAV          = 24;  % Real Time Navigation (Kalman Filter on Code and Phase Double Differences (with/without a constraint)
        MODE_RT_R_MON        = 21;  % Real Time Rover Monitor
        MODE_RT_M_MON        = 22;  % Real Time Master Monitor
        MODE_RT_RM_MON       = 23;  % Real Time Master + Rover Monitor
        
        MODE_PP_LS_C_SA      = 1;   % Post Proc Least Squares on Code Stand Alone
        MODE_PP_LS_CP_SA     = 3;   % Post Proc Least Squares on Code Stand Alone (BASE FOR FUTURE PPP IMPLEMENTATION)
        MODE_PP_LS_C_DD      = 11;  % Post Proc Least Squares on Code Double Differences
        MODE_PP_LS_CP_DD_L   = 13;  % Post Proc Least Squares on Code Double Differences with Lambda
        MODE_PP_LS_CP_VEL    = 3.1; % Post Proc Least Squares on Code and Phase for Velocity estimation
        
        MODE_PP_KF_C_SA      = 2;   % Post Proc Kalman Filter on Code Stand Alone
        MODE_PP_KF_C_DD      = 12;  % Post Proc Kalman Filter on Code Double Differencies
        MODE_PP_KF_CP_SA     = 4;   % Post Proc Kalman Filter on Code and Phase Stand Alone
        MODE_PP_KF_CP_DD     = 14;  % Post Proc Kalman Filter on Code and Phase Double Differences
        MODE_PP_KF_CP_DD_MR  = 15;  % Post Proc Kalman Filter on Code and Phase Double Differences Multiple Receivers
        
        GMODE_PP = [ goGNSS.MODE_PP_LS_C_SA ...     % Group of post processing modes
            goGNSS.MODE_PP_LS_CP_SA ...
            goGNSS.MODE_PP_LS_C_DD ...
            goGNSS.MODE_PP_LS_CP_DD_L ...
            goGNSS.MODE_PP_LS_CP_VEL ...
            goGNSS.MODE_PP_KF_C_SA ...
            goGNSS.MODE_PP_KF_C_DD ...
            goGNSS.MODE_PP_KF_CP_SA ...
            goGNSS.MODE_PP_KF_CP_DD ...
            goGNSS.MODE_PP_KF_CP_DD_MR];
        
        GMODE_RT = [ goGNSS.MODE_RT_NAV ...         % Group of real time modes
            goGNSS.MODE_RT_R_MON ...
            goGNSS.MODE_RT_M_MON ...
            goGNSS.MODE_RT_RM_MON];
        
        GMODE_SA = [ goGNSS.MODE_PP_LS_C_SA ...     % Group of stand alone modes
            goGNSS.MODE_PP_LS_CP_SA ...
            goGNSS.MODE_PP_LS_CP_VEL ...
            goGNSS.MODE_PP_KF_C_SA ...
            goGNSS.MODE_PP_KF_CP_SA];
        
        GMODE_DD = [ goGNSS.MODE_PP_LS_C_DD ...     % Group of double differences modes
            goGNSS.MODE_PP_LS_CP_DD_L ...
            goGNSS.MODE_PP_KF_C_DD ...
            goGNSS.MODE_PP_KF_CP_DD ...
            goGNSS.MODE_PP_KF_CP_DD_MR];
    end
    
    % Creator (empty)
    methods
        % Object to manage a useful functions / standard parameters of goGPS
        function obj = goGNSS()
        end
    end

    %   COMPATIBILITY FUNCTION (STATIC)
    % -------------------------------------------------------------------------
    % function to keep compatibility with the past
    methods (Static, Access = 'public')
        function f1 = F1()
        % GPS carriers frequencies F1
            f1 = goGNSS.FG(1);
        end        
        function f1 = F2()
        % GPS carriers frequencies F2
            f1 = goGNSS.FG(2);
        end
        
        function lambda1 = LAMBDA1()
        % GPS carriers frequency 1 [Hz]
            lambda1 = goGNSS.LAMBDAG(1);
        end
        
        function lambda2 = LAMBDA2()
        % GPS carriers frequency 2 [Hz]
            lambda2 = goGNSS.LAMBDAG(2);        

        end        
    end
    
    %   MODE FUNCTION (STATIC)
    % -------------------------------------------------------------------------
    % function to detect a certain kind of processing
    methods (Static, Access = 'public') 
        function isPostProcessing = isPP(mode)
        % return wheather or not the mode given in use is a Post Processing mode
            isPostProcessing = sum(intersect(mode, goGNSS.GMODE_PP));
        end
        
        function isRealTime = isRT(mode)
        % return wheather or not the mode given in use is a Real Time mode
            isRealTime = sum(intersect(mode, goGNSS.GMODE_RT));
        end
        
        function isDoubleDifferences = isDD(mode)
        % return wheather or not the mode given in use is a Double Difference mode
            isDoubleDifferences = sum(intersect(mode, goGNSS.GMODE_DD));
        end
        
        function isStandAlone = isSA(mode)
        % return wheather or not the mode given in use is a Stand Alone mode
            isStandAlone = sum(intersect(mode, goGNSS.GMODE_SA));
        end
    end
    
    %   USEFUL FUNCTION (STATIC)
    % -------------------------------------------------------------------------
    methods (Static, Access = 'public')
        
        function [XR, dtR] = getBancroftPos(XS, dtS, prR)
            % get a bancroft solution from one receiver

            matB = [XS(:,:), prR(:) + goGNSS.V_LIGHT * dtS(:)]; % Bancroft matrix
            b = obj.bancroft(matB);
            XR = b(1:3);
            dtR = b(4)/goGNSS.V_LIGHT;
        end
        
        function [X, dt, usableSat, satCoord, cov_X, var_dt, PDOP, HDOP, VDOP, cond_num] = LS_MR_C_SA(goObs, goIni)
            %------------------------------------------------------------------------------------
            % APPROXIMATE POSITION for the rovers and the master
            %-----------------------------------------------------------------------------------

            [XM0 flag_M] = goObs.getX0_M();    %[sized 3x1]
            
            % get a Least Squares solution using only Code Stand Alone using Master and Multiple Rover Receivers
            
            %----------------------------------------------------------------------------------------------
            % FIRST ESTIMATE OF SATELLITE POSITIONS from Master observations
            %----------------------------------------------------------------------------------------------
            % satellites in view by the master at the first epoch
            sat_pr_init = find(goObs.getTrackedSat(goGNSS.ID_GPS, 0, -1, 1, 1) ~= 0);
            % extract ephemerides for the first epoch
            Eph_1 = rt_find_eph (goObs.getGNSSeph(goGNSS.ID_GPS), goObs.getTime_Ref(1));
            
            [XS, dtS, XS_tx, VS_tx, time_tx, no_eph] = satellite_positions(goObs.getTime_M(1), goObs.getGNSSpr_M(goGNSS.ID_GPS, 0, 1, 1), sat_pr_init, Eph_1, goObs.getGNSS_SP3time(), goObs.getGNSS_SP3coordinates(), goObs.getGNSS_SP3clock(), goOBS.getSBAS(), [], goObs.getIono(), 0);
            
            %satellites with no ephemeris available
            usableSatM = (no_eph == 0);
            
            %----------------------------------------------------------------------------------------------
            % APPROXIMATE RECEIVER POSITION BY BANCROFT ALGORITHM
            %----------------------------------------------------------------------------------------------
            XR = zeros(3,goObs.getNumRec());
            prR = goObs.getGNSSpr_R(goGNSS.ID_GPS, 0, 0, 1, 1);
            for r=1:goObs.getNumRec()
                [XR(:,r), dtR] = getBancroftPos(XS(usableSatM,:), dtS(usableSatM), prR(usableSatM,r));
            end
            
            %----------------------------------------------------------------------------------------------
            % ELEVATION CUTOFF, SNR CUTOFF AND REMOVAL OF SATELLITES WITHOUT EPHEMERIS
            %----------------------------------------------------------------------------------------------
            
            satCoord = struct('az',zeros(goGNSS.MAX_SAT,goObs.getNumRec()+1),'el',zeros(goGNSS.MAX_SAT,goObs.getNumRec()+1),'dist',zeros(goGNSS.MAX_SAT,goObs.getNumRec()+1)); %first column: MASTER, further columns: ROVERS

            for r=1:goObs.getNumRec()
                %satellite topocentric coordinates (azimuth, elevation, distance)
                [satCoord.az(:,r+1), satCoord.el(:,r+1), satCoord.dist(:,r+1)] = topocent(XR(:,r), XS);
                %elevation cutoff, SNR cutoff and removal of satellites without ephemeris
                if (any(goObs.getGNSSsnr_R(goGNSS.ID_GPS, sat_pr_initR, r, 1, 1)))
                    usableSatR(:,r) = find((satCoord.el(:,r+1) > goIni.getCutoff) & ((goObs.getGNSSsnr_R(goGNSS.ID_GPS, sat_pr_initR, r, 1, 1) ~= 0) & (goObs.getGNSSsnr_R(goGNSS.ID_GPS, sat_pr_initR, r, 1, 1) > goIni.getSnrThr)) & (usableSatM));
                else
                    usableSatR(:,r) = find((satCoord.el(:,r+1) > goIni.getCutoff) & (usableSatM));
                end
            end
            %             %set the matrices for the ROVER least squares solutions
            % %             sat   = usableSatR;
            % %             pseudorange = prR;
            % %             snr  = goObs.getGNSSsnr_R(goGNSS.ID_GPS, sat_pr_initR, 0, 1, 1);
            % %             el   = satCoord.el(usableSatR,r);
            % %             az   = satCoord.az(usableSatR,r);
            % %             dist = satCoord.dist(usableSatR,r);
            % %             XS   = XS(usableSatM,:);
            % %             dtS  = dtS(usableSatM);
            % %             nsat = sum(usableSatR);
            
            %--------------------------------------------------------------------------------------------
            % LEAST SQUARES SOLUTION
            %--------------------------------------------------------------------------------------------
            if (sum(usableSatR(:)) >= 4*goObs.getNumRec())

                for r=1:goObs.getNumRec()
                    %cartesian to geodetic conversion of ROVER coordinates
                    [phiR(:,r), lamR(:,r), hR(:,r)] = cart2geod(XR(1,r), XR(2,r), XR(3,r));
                    
                    %radians to degrees
                    phiR = phiR * 180 / pi;
                    lamR = lamR * 180 / pi;
                    
                    %computation of tropospheric errors
                    err_tropo(:,r) = tropo_error_correction(satCoord.el(:,r+1), hR(:,r));
                    
                    %computation of ionospheric errors
                    err_iono(:,r) = iono_error_correction(phiR(:,r), lamR(:,r), satCoord.az(:,r+1), satCoord.el(:,r+1), goObs.getTime_Ref(1), goObs.getIono(), sbas);
                end

                %LS solution for ROVER receivers
                [XR, dtR, cov_XR, var_dtR, PDOP, HDOP, VDOP, cond_num] = LS_SA_code(XR, XS, pseudorange, snr, el, dist, dtS, err_tropo, err_iono);
                
                for r=1:goObs.getNumRec()
                    %satellite topocentric coordinates (azimuth, elevation, distance)
                    [satCoord.az(:,r), satCoord.el(:,r), satCoord.dist(:,r)] = topocent(XR(:,r), XS);
                end
            else
                %empty variables
                dtR = [];
                err_tropo = [];
                err_iono  = [];
                
                cov_XR = [];
                var_dtR = [];
                
                PDOP = -9999;
                HDOP = -9999;
                VDOP = -9999;
                cond_num = [];
            end
            
        end
        
    end
    
    methods (Static, Access = 'private')
        % Bancroft algorithm for the computation of ground coordinates
        % having at least 4 visible satellites.
        function pos = bancroft(matB)
            % SYNTAX:
            %   [pos] = bancroft(B_pass);
            %
            % INPUT:
            %   B_pass = Bancroft matrix
            %
            % OUTPUT:
            %   pos = approximated ground position (X,Y,Z coordinates)
            %
            % DESCRIPTION:
            %   Bancroft algorithm for the computation of ground coordinates
            %   having at least 4 visible satellites.
            %
            % Copyright (C) Kai Borre
            % Kai Borre 04-30-95, improved by C.C. Goad 11-24-96
            %
            % Adapted by Mirko Reguzzoni, Eugenio Realini, 2009
            %----------------------------------------------------------------------------------------------
            
            pos = zeros(4,1);   % Init position of the receiver
            
            nSat = size(matB,1);
            
            for iter = 1:2
                % Compute correctionon XS coordinates
                % due to the rotation of the Earth
                for s = 1:nSat
                    x = matB(s,1);      % X coordinate of the satellite S
                    y = matB(s,2);      % Y coordinate of the satellite S
                    if iter == 1
                        traveltime = 0.072; % [s]
                    else
                        z = matB(s,3);  % Z coordinate of the satellite S
                        % Compute approximate distance^2 between R and S
                        rho = (x-pos(1))^2+(y-pos(2))^2+(z-pos(3))^2;
                        traveltime = sqrt(rho)/goGNSS.V_LIGHT;
                    end
                    angle = traveltime*goGNSS.OMEGAE_DOT;
                    cosa = cos(angle);
                    sina = sin(angle);
                    % Applying correction (rotation)
                    matB(s,1) =	cosa*x + sina*y;
                    matB(s,2) = -sina*x + cosa*y;
                end % i-loop
                
                % Criptical way to implement Bancroft
                if nSat > 4
                    BBB = (matB'*matB)\matB';
                else
                    BBB = inv(matB);
                end
                e = ones(nSat,1);
                alpha = zeros(nSat,1);
                for s = 1:nSat
                    alpha(s) = lorentz(matB(s,:)',matB(s,:)')/2;
                end
                BBBe = BBB*e;
                BBBalpha = BBB*alpha;
                a = lorentz(BBBe,BBBe);
                b = lorentz(BBBe,BBBalpha)-1;
                c = lorentz(BBBalpha,BBBalpha);
                root = sqrt(b*b-a*c);
                r(1) = (-b-root)/a;
                r(2) = (-b+root)/a;
                possible_pos = zeros(4,2);
                for s = 1:2
                    possible_pos(:,s) = r(s)*BBBe+BBBalpha;
                    possible_pos(4,s) = -possible_pos(4,s);
                end
                
                abs_omc = zeros(2,1);
                for s =1:nSat
                    for i = 1:2
                        c_dt = possible_pos(4,i);
                        calc = norm(matB(s,1:3)' -possible_pos(1:3,i))+c_dt;
                        omc = matB(s,4)-calc;
                        abs_omc(i) = abs(omc);
                    end
                end; % j-loop
                
                % discrimination between roots
                if abs_omc(1) > abs_omc(2)
                    pos = possible_pos(:,2);
                else
                    pos = possible_pos(:,1);
                end
            end;
        end
    end
    
end
