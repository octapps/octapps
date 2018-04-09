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
## @deftypefn {Function File} {@var{X} =} possibilities ( @var{x}, @var{N} )
##
## Build a matrix whos columns are all possible selections of N elements
## from the vector x, in the order that would be given by an N-dimensional
## nested loop. For example:
##
## @verbatim
## M = [];
## for ii = possibilities(-1:1, 3);
##   M = [M, ii];
## endfor
## @end verbatim
##
## will produce the same matrix M as:
##
## @verbatim
## M = [];
## for i = -1:1
##   for j = -1:1
##     for k = -1:1
##       M = [M, [i;j;k]];
##     endfor
##   endfor
## endfor
## @end verbatim
##
## except that the dimensionality N can be determine at run time
##
## @end deftypefn

function X = possibilities(x, N)

  ## check input
  assert(isvector(x));
  assert(N >= 1);

  ## bui
  x = x(:)';
  X = x;
  for n = 2:N
    X = [reshape(repmat(x, length(x)^(n-1), 1), 1, []); repmat(X, 1, length(x))];
  endfor

endfunction

%!test
%!  M1 = [];
%!  for ii = possibilities(-1:1, 3);
%!    M1 = [M1, ii];
%!  endfor
%!  M2 = [];
%!  for i = -1:1
%!    for j = -1:1
%!      for k = -1:1
%!        M2 = [M2, [i;j;k]];
%!      endfor
%!    endfor
%!  endfor
%!  assert(M1, M2);
