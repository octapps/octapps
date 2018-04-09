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
## @deftypefn {Function File} {@var{GPS} =} MJDutc_to_GPS ( @var{MJDutc} )
##
## convert MJD (based on UTC) into GPS seconds
## translated from lalapps-CVS/src/pulsar/TDS_isolated/TargetedPulsars.c
## This conversion corresponds to what @command{lalapps_tconvert} does, but
## is NOT the right thing for pulsar timing, as pulsar-epochs are typically
## given in MJD(TDB) ! ==> use MJDtdb_to_GPS.m for that purpose!
##
## @end deftypefn

function GPS = MJDutc_to_GPS ( MJDutc )

  REF_GPS_SECS=793130413.0;
  REF_MJD=53423.75;

  GPS = (-REF_MJD + MJDutc) * 86400.0 + REF_GPS_SECS;

  return;

endfunction

%!assert(MJDutc_to_GPS(45123), 75945613, 1e-6)
%!assert(MJDutc_to_GPS(123456), 6843916813, 1e-6)
