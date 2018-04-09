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
## @deftypefn {Function File} {@var{A} =} arrayflatten ( @var{X}, @dots{} )
##
## Flatten the arguments @var{X}, @dots{} into one array vector @var{A}.
## @end deftypefn

function A = arrayflatten(varargin)
  C = cellflatten(varargin{:});
  A = [];
  for i = 1:length(C)
    A = [A, double(reshape(C{i}, 1, []))];
  endfor
  if numel(A) == 0
    A = [];
  endif
endfunction

%!assert(all(arrayflatten([]) == []))
%!assert(all(arrayflatten([1]) == [1]))
%!assert(all(arrayflatten([1,2]) == [1,2]))
%!assert(all(arrayflatten([1,2],3) == [1,2,3]))
%!assert(all(arrayflatten([1;2;3],4) == [1,2,3,4]))
%!assert(all(arrayflatten([1,2;3,4]',5) == [1,2,3,4,5]))
