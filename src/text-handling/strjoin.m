## Copyright (C) 2013 Karl Wette
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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} {@var{s} =} strjoin ( @var{cstr}, @var{sep} )
##
## Join the cell array of strings @var{cstr} using the separator @var{sep}
## and return the joined string.
## @end deftypefn

function s = strjoin(cstr, sep)

  ## check input
  assert(nargin == 2);
  assert(iscell(cstr));
  assert(all(cellfun(@ischar, cstr)));
  assert(ischar(sep));

  ## join string
  if length(cstr) == 1
    s = cstr{1};
  else
    s = cstrcat(cellfun(@(cs) cstrcat(cs, sep), cstr(1:end-1), "UniformOutput", false){:}, cstr{end});
  endif

endfunction

%!assert(strcmp(strjoin({"a"},","), "a"))
%!assert(strcmp(strjoin({"a","b","c"},","), "a,b,c"))
%!assert(strcmp(strjoin({" a","b "," c "},","), " a,b , c "))
