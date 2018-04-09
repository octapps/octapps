## Copyright (C) 2018 Karl Wette
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
## @deftypefn
##
## Helper function for OctApps @command{make check}.
##
## @end deftypefn

function __octapps_make_check__(fn)
  crash_dumps_octave_core(0);
  [d, n] = fileparts(fn);
  fn = fullfile(d, n);
  [htext, hfmt] = get_help_text(fn);
  assert(length(strtrim(htext)) > 0, "help message is missing");
  assert(strcmp(hfmt, "texinfo"), "help message is not in Texinfo format");
  makeinfo_program(sprintf("%s --verbose --error-limit=0", makeinfo_program()), "local");
  [hfmttext, status] = __makeinfo__(htext);
  assert(status == 0, "help message has some Texinfo errors");
  test(fn);
endfunction
