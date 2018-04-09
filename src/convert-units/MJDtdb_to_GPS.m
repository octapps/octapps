## Copyright (C) 2006 Matthew Pitkin
## Copyright (C) 2007 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {@var{GPS} =} MJDtdb_to_GPS ( @var{MJD_tdb} )
##
## convert MJD (based on TDB) into GPS seconds
## translated from LAL-function @command{LALTDBMJDtoGPS()} in BinaryPulsarTiming.c
##
## @end deftypefn

function GPS = MJDtdb_to_GPS ( MJD_tdb )

  ## Check not before the start of GPS time (MJD 44222)
  if(MJD_tdb < 44244)
    error("Input time is not in range [earlier than MJD0=44244].\n");
  endif

  Tdiff = MJD_tdb + (2400000.5 - 2451545.0);
  meanAnomaly = 357.53 + 0.98560028 * Tdiff;    ## mean anomaly in degrees
  meanAnomaly *= pi/180;                        ## mean anomaly in rads

  TDBtoTT = 0.001658 * sin(meanAnomaly) + 0.000014 * sin(2 * meanAnomaly); ## time diff in seconds

  ## convert TDB to TT (TDB-TDBtoTT) and then convert TT to GPS
  ## there is the magical number factor of 32.184 + 19 leap seconds to the start of GPS time
  GPS = ( MJD_tdb - 44244) * 86400 - 51.184 - TDBtoTT;

  return;

endfunction

%!assert(MJDtt_to_GPS(45123), 75945548.816, 1e-6)
%!assert(MJDtt_to_GPS(123456), 6843916748.816, 1e-6)
