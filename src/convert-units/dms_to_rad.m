## Copyright (C) 2010 Reinhard Prix
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
## @deftypefn {Function File} {@var{ret} =} dms_to_rad ( @var{degs} )
##
## convert degrees in the format "deg:min:sec.xx" into radians
##
## @end deftypefn

function ret = dms_to_rad ( degs )

  tmp = strtrim ( degs );

  numColons = length ( strchr ( degs, ":" ) );
  assert ( numColons == 2, "Invalid input string 'degs', must be of the form 'deg:mins:sec.xx'\n", tmp );

  if ( tmp(1) == '-' )
    degsign = -1;
  else
    degsign = +1;
  endif

  tokens = strsplit (degs, ":" );

  degsNum = str2num ( tokens{1} );
  minutes = str2num ( tokens{2} );
  seconds = str2num ( tokens{3} );

  degsDecimal = ( degsNum + degsign*minutes/60.0 + degsign*seconds/3600.0 );

  ret = degsDecimal * (pi/180);

  return;

endfunction

%!test
%!  rads = dms_to_rad ( "10:11:12.345" );
%!  rads0 = (10 + 11/60 + 12.345/3600)*pi/180;
%!  assert ( rads, rads0, eps );
%!  [sig, dd,mm,ss] = rad_to_dms ( rads );
%!  assert ( sig, 1 ); assert ( dd, 10 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );

%!test
%!  rads = dms_to_rad ( "-10:11:12.345" );
%!  rads0 = -(10 + 11/60 + 12.345/3600)*pi/180;
%!  assert ( rads, rads0, eps );
%!  [sig, dd,mm,ss] = rad_to_dms ( rads );
%!  assert (sig, -1 ); assert ( dd, 10 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );

%!test
%!  rads = dms_to_rad ( "-0:11:12.345" );
%!  rads0 = -(11/60 + 12.345/3600)*pi/180;
%!  assert ( rads, rads0, eps );
%!  [sig, dd,mm,ss] = rad_to_dms ( rads );
%!  assert ( sig, -1 ); assert ( dd, 0 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );
