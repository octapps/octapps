## Copyright (C) 2017 Karl Wette
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
## @deftypefn {Function File} {@var{hex} =} versionstr2hex ( @var{str} )
##
## Convert a version string into a hexadecimal number for easy comparisons.
##
## @end deftypefn

function hex = versionstr2hex(str)
  strs = strsplit(str, ".");
  hex = 0;
  for i = 1:length(strs)
    s = fix(str2double(strs{i}));
    hex = hex * 256 + floor(s / 10) * 16 + rem(s, 10);
  endfor
endfunction

%!assert(versionstr2hex("2.10.99.3"), 0x02109903)
