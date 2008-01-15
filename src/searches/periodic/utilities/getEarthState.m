%% input: earth-ephemeris file (load with loadEphemeris()) and gps-time
%% interpolate earth-state at gps-time from given ephemeris-table
%% returns 'earthState' struct with elements { pos, vel, acc, accDot }
%%

%%
%% Copyright (C) 2006 Reinhard Prix
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%


function ret = getEarthState (ephem, gps)

  tinitE = ephem(1,1);	% start-time of ephemeris-table
  dtEtable = ephem(2,1) - ephem(1,1); % time-interval of ephemeris-table

  t0e = gps - tinitE;
  ientryE = 1 + floor( (t0e/dtEtable) + 0.5);  % round to closest entry
  tdiffE = t0e - dtEtable*(ientryE-1) ;  % time-offset from that entry

  posI = ephem(ientryE, 2:4);
  velI = ephem(ientryE, 5:7);
  accI = ephem(ientryE, 8:10);

  %% get neighbour-bin for interpolation/differentiation
  if (tdiffE >= 0)
    i0 =  ientryE;
    weight0 = 1- (tdiffE / dtEtable);
  else
    i0 = ientryE -1;
    weight0 = tdiffE / dtEtable;
  endif

  acc0 = ephem(i0, 8:10);
  acc1 = ephem(i0+1, 8:10);

  %% interpolate
  ret.pos = posI + velI * tdiffE + 0.5 * accI * tdiffE^2;
  ret.vel = velI + accI * tdiffE;
  ret.acc = weight0 * acc0 + (1-weight0) * acc1;

  ret.accDot = (acc1 - acc0) / dtEtable;   % rough estimate

  return;

endfunction %% getEarthState()
