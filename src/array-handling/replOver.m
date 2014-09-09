## Copyright (C) 2013 Karl Wette
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

## Replicate x over dimensions dims, so that its final size is siz.
## Usage:
##   x = replOver(x, dims, siz)

function x = replOver(x, dims, siz)

  ## check input
  assert(ismatrix(x));
  ndims = length(siz);
  assert(all(1 <= dims & dims <= ndims));

  ## determine remaining dimensions, and check size of x
  rd = setdiff(1:ndims, dims);
  if length(rd) == 1
    assert(numel(x) == siz(rd));
  else
    assert(all(size(x) == siz(rd)));
  endif

  ## return x duplicated over all dimensions in dims
  ## - taken from ndgrid.m
  r = ones(size(siz));
  r(rd) = siz(rd);
  s = siz;
  s(rd) = 1;
  x = repmat(reshape(x, r), s);

endfunction
