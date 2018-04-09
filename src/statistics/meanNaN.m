## Copyright (C) 2014 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{y} =} meanNaN ( @var{x}, @var{dim} )
##
## Compute the mean of @var{x} over the dimension @var{dim}, ignoring NaNs.
## @end deftypefn

function Y = meanNaN(X, dim=[])

  ## if no 'dim' supplied, find the smallest non-singleton dimension
  if isempty(dim)
    (dim = find(size(X) > 1, 1)) || (dim = 1);
  endif

  ## compute denominators, counting non-NaN values;
  ## if all entries are NaNs, mean is also NaN
  N = sum(!isnan(X), dim);
  N(N == 0) = NaN;

  ## compute means, after zeroing out NaN values
  X(isnan(X)) = 0;
  Y = sum(X, dim) ./ N;

endfunction

%!assert(meanNaN([1:5, NaN, 6:10]), mean(1:10))
