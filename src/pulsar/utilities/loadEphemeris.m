%% Copyright (C) 2006 Reinhard Prix
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with with program; see the file COPYING. If not, write to the
%% Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%% MA  02111-1307  USA

%% ephem = loadEphemeris (fname)
%%
%% load in a given earth ephemeris-file
%% and returns a list of [gps, pos, vel, acc]

function ephem = loadEphemeris (fname)

  fid = fopen(fname, "rb");
  if ( fid == -1 )
    error ("Failed to load ephemeris-file '%s' \n", fname );
  endif

  [ gpsYr, deltaT, nEntries ] = fscanf(fid, "%f %f %f\n", "C");
  data = fscanf(fid, "%f");
  fclose(fid);

  ephem = reshape(data, 10, nEntries);
  ephem = ephem' ;

  return;

endfunction %% loadEphemeris()
