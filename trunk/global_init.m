% SYNTAX:
%   global_init;
%
% DESCRIPTION:
%   Global variables initialization.

%----------------------------------------------------------------------------------------------
%                           goGPS v0.1 alpha
%
% Copyright (C) 2009 Mirko Reguzzoni*, Eugenio Realini**
%
% * Laboratorio di Geomatica, Polo Regionale di Como, Politecnico di Milano, Italy
% ** Media Center, Osaka City University, Japan
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

%-------------------------------------------------------------------------------
% CONSTANTS
%-------------------------------------------------------------------------------

global v_light
global f1 f2
global lambda1 lambda2
global a e f
global GM Omegae_dot

%velocity of light in the void
v_light = 299792458; % [m/s]

%GPS carriers frequencies
f1 = 1575420000; % [1/s]
f2 = 1227600000; % [1/s]

%GPS carriers wavelengths
lambda1 = v_light / f1; % [m]
lambda2 = v_light / f2; % [m]

%ellipsoid semi-major axis
a = 6378137; % [m]

%ellipsoid flattening
f = 1/298.257222101;

%eccentricity
e = sqrt(1-(1-f)^2);

%gravitational constant (mass of Earth)
GM = 3.986004418e14; % [m^3/s^2]

%angular velocity of the Earth rotation
Omegae_dot = 7.2921151467e-5; % [rad/s]

%-------------------------------------------------------------------------------
% SATELLITE CONFIGURATION
%-------------------------------------------------------------------------------

global azR elR distR
global azM elM distM

%azimuth, elevation and distance of satellites with respect to the ROVER
azR = [];
elR = [];
distR = [];

%azimuth, elevation and distance of satellites with respect to the MASTER
azM = [];
elM = [];
distM = [];

%-------------------------------------------------------------------------------
% KALMAN FILTER
%-------------------------------------------------------------------------------

%transition matrix
global T

%identity matrix
global I

%state estimation at time t
global Xhat_t_t 

%state estimation at time t+1 (using dynamics only)
global X_t1_t

%estimation error covariance matrix at time t
global Cee 

%number of visible satellites at time t
global nsat  %%% Developer's note: OBSOLETE %%%

%satellite configuration (1: visible, 0: not visible) at time t
global conf_sat

%cycle-slip configuration (1: cs, 0: no cs) at time t
global conf_cs 

%index of the current pivot satellite
global pivot

%index of the previous pivot satellite
global pivot_old

%number of unknown phase ambiguities
global nN

%initialization
T = [];
I = [];
Xhat_t_t = [];
X_t1_t = [];
Cee = [];
nsat = [];
conf_sat = [];
conf_cs = [];
pivot = [];
pivot_old = [];
nN = [];

%-------------------------------------------------------------------------------
% KALMAN FILTER (CONSTRAINED VERSION)
%-------------------------------------------------------------------------------

%constrained trajectory
global s0 
global ax
global ay
global az
global Yhat_t_t
global Y_t1_t

%-------------------------------------------------------------------------------
% REAL-TIME MANAGEMENT
%-------------------------------------------------------------------------------
global master rover

%-------------------------------------------------------------------------------
% MASTER STATION
%-------------------------------------------------------------------------------

global server_delay nmea_update_rate

%server waiting time (to check if packet transmission is finished)
server_delay = 0.05;

%NMEA update rate (waiting time for sending a new $GGA string to NTRIP caster)
nmea_update_rate = 10; %[sec]

%-------------------------------------------------------------------------------
% INTERNET CONNECTION
%-------------------------------------------------------------------------------

global connection_delay

%waiting time for the Internet connection to be established
connection_delay = 5;

%-------------------------------------------------------------------------------
% MATLAB DISPLAY
%-------------------------------------------------------------------------------

global p_max pid
global window
global x_circle id_ellipse

%maximum number of drawn trajectory points
p_max = 200;

%trajectory point id
pid = zeros(p_max,1);

%master station point id
msid = [];

%dimension of the time windows (ambiguity plot)
window = 20;

%reference circle (for covariance plot)
try
    % if Statistics Toolbox is installed
    alpha = 0.05;                       % significance level
    r = sqrt(chi2inv(1-alpha,2));       % circle radius
catch
    % if Statistics Toolbox is not installed,
    % then alpha = 0.05, chi2inv(1-alpha,2) = 5.991
    r = sqrt(5.991);
end
theta = (0 : 2*pi/100 : 2*pi)';     % angle values
x_circle(:,1) = r * cos(theta);     % x-coordinate of the circle
x_circle(:,2) = r * sin(theta);     % y-coordinate of the circle

%error ellipse identifier
id_ellipse = [];

%-------------------------------------------------------------------------------
% GOOGLE EARTH
%-------------------------------------------------------------------------------

global link_filename kml_filename

%files used by Google Earth
link_filename = '../data/google_earth/link.kml';
kml_filename = '../data/google_earth/goGPS.kml';