function [Obs_columns, nObs_types] = obs_type_find(Obs_types)

% SYNTAX:
%   [Obs_columns, nObs_types] = obs_type_find(Obs_types);
%
% INPUT:
%   Obs_types = string containing observation types
%
% OUTPUT:
%   Obs_columns = structure containing the column number of each observation type
%                 in the following fields:
%                   L1 = L1 column (or LA for RINEX v2.12)
%                   L2 = L2 column (or LC for RINEX v2.12)
%                   C1 = C1 column (or CA for RINEX v2.12)
%                   P1 = P1 column (or CA for RINEX v2.12)
%                   P2 = P2 column (or CC for RINEX v2.12)
%                   S1 = S1 column (or SA for RINEX v2.12)
%                   S2 = S2 column (or SC for RINEX v2.12)
%                   D1 = D1 column (or DA for RINEX v2.12)
%                   D2 = D2 column (or DC for RINEX v2.12)
%   nObs_types = number of available observation types
%
% DESCRIPTION:
%   Detection of the column index for phase observations (L1, L2), for
%   code observations (C1, P1, P2), SNR ratios (S1, S2) and Doppler
%   measurements (D1, D2).

%----------------------------------------------------------------------------------------------
%                           goGPS v0.3.1 beta
%
% Copyright (C) 2009-2012 Mirko Reguzzoni,Eugenio Realini
% Portions of code contributed by Damiano Triglione (2012)
%
% Partially based on FOBS_TYP.M (EASY suite) by Kai Borre
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

%search L1 column
s1 = strfind(Obs_types, 'L1'); %findstr is obsolete, so strfind is used
s2 = strfind(Obs_types, 'LA');
s = [s1 s2];
col_L1 = (s+1)/2;

%search L2 column
s1 = strfind(Obs_types, 'L2');
s2 = strfind(Obs_types, 'LC');
s = [s1 s2];
col_L2 = (s+1)/2;

%search C1 column
s1 = strfind(Obs_types, 'C1');
s2 = strfind(Obs_types, 'CA');
s = [s1 s2];
col_C1 = (s+1)/2;

%search P1 column
s1 = strfind(Obs_types, 'P1');
s2 = strfind(Obs_types, 'CA'); %QZSS does not use P1
s = [s1 s2];
col_P1 = (s+1)/2;

%if RINEX v2.12 and GPS/GLONASS P1 observations are not available
if (length(col_P1) ~= 2 && ~isempty(s2))
    %keep QZSS CA observations as C1
    col_P1 = [];
end

%search P2 column
s1 = strfind(Obs_types, 'P2');
s2 = strfind(Obs_types, 'CC');
s = [s1 s2];
col_P2 = (s+1)/2;

%search S1 column
s1 = strfind(Obs_types, 'S1');
s2 = strfind(Obs_types, 'SA');
s = [s1 s2];
col_S1 = (s+1)/2;

%search S2 column
s1 = strfind(Obs_types, 'S2');
s2 = strfind(Obs_types, 'SC');
s = [s1 s2];
col_S2 = (s+1)/2;

%search D1 column
s1 = strfind(Obs_types, 'D1');
s2 = strfind(Obs_types, 'DA');
s = [s1 s2];
col_D1 = (s+1)/2;

%search D2 column
s1 = strfind(Obs_types, 'D2');
s2 = strfind(Obs_types, 'DC');
s = [s1 s2];
col_D2 = (s+1)/2;

Obs_columns.L1 = col_L1;
Obs_columns.L2 = col_L2;
Obs_columns.C1 = col_C1;
Obs_columns.P1 = col_P1;
Obs_columns.P2 = col_P2;
Obs_columns.S1 = col_S1;
Obs_columns.S2 = col_S2;
Obs_columns.D1 = col_D1;
Obs_columns.D2 = col_D2;

nObs_types = 0;
types = fieldnames(Obs_columns);
for i = 1 : numel(types)
    if (~isempty(Obs_columns.(types{i})))
        nObs_types = nObs_types + 1;
    end
end
