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
## @deftypefn {Function File} {@var{ret} =} rngmed ( @var{data}, @var{window} )
##
## return a 'smoothed' vector using a
## running-median of the given @var{window}-size.
## output-vector has same number of entries, with @var{window}/2 bins
## at the borders filled with identical values
##
## @heading Note
##
## this is the most 'naive' implementation, not optimized at all!
## @end deftypefn

function ret = rngmed ( data, window )
  ret = data;

  len = length(data);
  winl = ceil(window/2);
  winr = floor(window/2);

  for i = 1:len
    i0 = max(1,i - winl);
    i1 = min(i + winr,len);
    ret(i) = median ( data (i0:i1) );
  endfor

  return;

endfunction

%!assert(rngmed(1:10, 3), [1.5 2.0 2.5 3.5 4.5 5.5 6.5 7.5 8.5 9.0])
