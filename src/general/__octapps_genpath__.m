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
## @deftypefn
##
## Generates the Octave path for OctApps.
##
## @end deftypefn

function __octapps_genpath__()
  octvhex = versionstr2hex(OCTAVE_VERSION);
  srcbasedir = canonicalize_file_name(fullfile(fileparts(mfilename("fullpath")), ".."));
  assert(exist(srcbasedir, "dir"));
  srcdirs = strsplit(genpath(srcbasedir), ':');
  for i = 1:length(srcdirs)
    srcdir = srcdirs{i};
    assert(exist(srcdir, "dir"));
    srcdirname = strsplit(srcdir, filesep){end};
    if strncmp(srcdirname, "compat-pre-", 11)
      vhex = versionstr2hex(srcdirname(12:end));
      if octvhex < vhex
        printf("%s ", srcdir);
      endif
    else
      printf("%s ", srcdir);
    endif
  endfor
  printf("\n");
endfunction
