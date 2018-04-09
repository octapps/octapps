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
## @deftypefn {Function File} {@var{C} =} cellflatten ( @var{X}, @dots{} )
##
## Flatten the arguments @var{X}, @dots{} into one cell vector @var{C}.
## @end deftypefn

function C = cellflatten(varargin)
  C = {};
  for i = 1:length(varargin)
    X = varargin{i};
    if iscell(X)
      C = {C{:}, cellflatten(X{:}){:}};
    else
      C{end+1} = X;
    endif
  endfor
  if length(C) > 0
    C = reshape(C, 1, []);
  endif
endfunction

%!assert(all(cellfun(@eq, cellflatten({}), {})))
%!assert(all(cellfun(@eq, cellflatten({1}), {1})))
%!assert(all(cellfun(@eq, cellflatten({1,2}), {1,2})))
%!assert(all(cellfun(@eq, cellflatten({1,2},3), {1,2,3})))
%!assert(all(cellfun(@eq, cellflatten({{1},{2},3},4), {1,2,3,4})))
%!assert(all(cellfun(@eq, cellflatten({{1,2},{3,4},5}), {1,2,3,4,5})))
