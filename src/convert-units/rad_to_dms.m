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
## @deftypefn {Function File} { [ @var{sig}, @var{degs}, @var{mins}, @var{secs} ] =} rad_to_dms ( @var{rads} )
##
## convert radians 'rads' into degrees "<sig>degs:minutes:secs", where <sig> is either +1 or -1
##
## @end deftypefn

function [sig, degs, mins, secs] = rad_to_dms ( rads )

  sig = sign ( rads );

  degDecimal = abs(rads) * (180 / pi );

  degs = fix ( degDecimal );

  remdr1 = degDecimal - degs;
  mins = fix ( remdr1 * 60 );

  remdr2 = remdr1 - mins / 60;
  secs = remdr2 * 3600;

  return;

endfunction

%!test
%!  rads = dms_to_rad ( "10:11:12.345" );
%!  [sig, dd,mm,ss] = rad_to_dms ( rads );
%!  assert ( sig, 1 ); assert ( dd, 10 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );

%!test
%!  rads = dms_to_rad ( "-10:11:12.345" );
%!  [sig, dd,mm,ss] = rad_to_dms ( rads );
%!  assert (sig, -1 ); assert ( dd, 10 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );

%!test
%!  rads = dms_to_rad ( "-0:11:12.345" );
%!  [sig, dd,mm,ss] = rad_to_dms ( rads );
%!  assert ( sig, -1 ); assert ( dd, 0 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );
