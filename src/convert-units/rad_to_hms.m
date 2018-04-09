## Copyright (C) 2013 Reinhard Prix
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
## @deftypefn {Function File} { [ @var{hours}, @var{mins}, @var{secs} ] =} rad_to_hms ( @var{rads} )
##
## convert radians into hours:minutes:seconds format
##
## @end deftypefn

function [ hours, mins, secs ] = rad_to_hms ( rads )

  assert ( rads >= 0, "Only positive angles allowed, got '%f'\n", rads );

  hoursDecimal = rads * (12 / pi );

  hours = fix ( hoursDecimal );

  remdr1 = hoursDecimal - hours;
  mins = fix ( remdr1 * 60 );

  remdr2 = remdr1 - mins / 60;
  secs = remdr2 * 3600;

  return;
endfunction

%!test
%!  rads = hms_to_rad ( "10:11:12.345" );
%!  [hh, mm, ss] = rad_to_hms ( rads );
%!  assert ( hh, 10 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e4*eps );

%!test
%!  rads = hms_to_rad ( "0:11:12.345" );
%!  [hh, mm, ss] = rad_to_hms ( rads );
%!  assert ( hh, 0 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e4*eps );
