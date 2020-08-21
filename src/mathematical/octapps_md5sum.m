## Copyright (C) 2020 Karl Wette
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
## @deftypefn {Function File} octapps_md5sum ( @var{str} )
##
## Calculate the MD5 hash value of the string @var{str}.
##
## @end deftypefn

function md5 = octapps_md5sum(str)
  if exist("hash") == 5
    md5 = hash("md5", str);
  elseif exist("md5sum") == 5
    md5 = md5sum(str, true);
  else
    error("No MD5 hash function available");
  endif
endfunction

%!assert(octapps_md5sum("octapps"), "ab220839eb6a31c782f1726f1031f2d3")
