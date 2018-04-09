## Copyright (C) 2006 Reinhard Prix
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
## @deftypefn {Function File} {@var{ret} =} pickFromRange ( @var{range}, [ @var{num} ] )
##
## function to return a number of random-values (specified by the optional
## argument @var{num}, default is 1. Return is a column-vector) from within 'range',
## which can be a single number, or a vector with [min, max] entries
##
## @end deftypefn

function ret = pickFromRange(range, num)
  if ( !exist("num") )
    num = 1;
  endif

  if ( length(range) == 1 )
    ret = range * ones(num,1);
    return;             ## trivial case
  endif
  if ( rows(range) * columns(range) > 2 )
    error ("Illegal input to pickFromRange(): input either a scalar or an array[2]");
  endif

  minVal = min( range(:) );
  maxVal = max( range(:) );

  ret = minVal + rand(num,1) * ( maxVal - minVal );

endfunction

%!test
%!  pickFromRange([10,20],5);
