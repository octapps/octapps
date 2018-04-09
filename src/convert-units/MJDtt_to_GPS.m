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
## @deftypefn {Function File} {@var{GPS} =} MJDtt_to_GPS ( @var{MJDtt} )
##
## convert MJD (based on TT) into GPS seconds
## translated from LAL-function @command{LALTTMJDtoGPS()} in BinaryPulsarTiming.c
##
## @end deftypefn

function GPS = MJDtt_to_GPS ( MJDtt )

  ## Check not before the start of GPS time (MJD 44222)
  if (MJDtt < 44244)
    error ("Input time is not in range [before MJD0 = 44222].\n");
  endif

  ## there is the magical number factor of 32.184 + 19 leap seconds to the start of GPS time
  GPS = (MJDtt - 44244) * 86400 - 51.184;

  return;
endfunction

%!assert(MJDtt_to_GPS(45123), 75945548.816, 1e-6)
%!assert(MJDtt_to_GPS(123456), 6843916748.816, 1e-6)
