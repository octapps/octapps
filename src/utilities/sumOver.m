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

## Sum the array x over the given dimensions dims.
## Usage:
##   x = sumOver(x, dims)

function x = sumOver(x, dims)

  ## check input
  assert(ismatrix(x));
  if length(x) == numel(x)
    ndims = 1;
  else
    ndims = length(size(x));
  endif
  assert(all(1 <= dims & dims <= ndims));

  ## determine remaining dimensions
  rd = setdiff(1:ndims, dims);

  ## permute array so that remaining dimensions are first
  perm = 1:ndims;
  perm(rd) = [];
  perm = [rd, perm];
  x = permute(x, perm);

  ## flatten dimensions which are being summed over
  siz = size(x);
  n = length(rd);
  x = reshape(x, [siz(1:n), prod(siz(n+1:end))]);

  ## sum over last dimension
  x = sum(x, n+1);  

endfunction


## test summing over an array of integers
%!shared x
%! x = reshape(1:4^4, 4*ones(4,1));

%!test
%! for i = 1:4
%!   assert(all(reshape(sum(x, i), 1, []) == reshape(sumOver(x, i), 1, [])));
%! endfor

%!test
%! for i = 1:4
%!    for j = 1:4
%!       assert(all(reshape(sum(sum(x, i), j), 1, []) == reshape(sumOver(x, [i, j]), 1, [])));
%!    endfor
%! endfor

%!test
%! for i = 1:4
%!    for j = 1:4
%!       for k = 1:4
%!          assert(all(reshape(sum(sum(sum(x, i), j), k), 1, []) == reshape(sumOver(x, [i, j, k]), 1, [])));
%!       endfor
%!    endfor
%! endfor
