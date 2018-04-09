## Copyright (C) 2011 Karl Wette
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
## @deftypefn {Function File} {} unmanglePATH
##
## Aaargh Octave! At startup it prepends PATH with directories containing
## Octave executables - which if it's installed in @file{/usr/bin} include
## @file{/usr/bin}. This will clobber any existing paths in PATH that were meant
## to override @file{/usr/bin}, such as e.g. custom installation of LALSuite!
##
## This script undoes the damage.
##
## @end deftypefn

function unmanglePATH

  path = strsplit(getenv("PATH"), ":");
  newpath = "";
  found_usr_bin = 0;
  for i = length(path):-1:1
    if strcmp(path{i}, "/usr/bin")
      if found_usr_bin
        path{i} = "";
      else
        found_usr_bin = 1;
      endif
    endif
    if length(path{i}) > 0
      if length(newpath) > 0
        newpath = strcat(":", newpath);
      endif
      newpath = strcat(path{i}, newpath);
    endif
  endfor
  setenv("PATH", newpath);

endfunction

%!test
%!  unmanglePATH();
