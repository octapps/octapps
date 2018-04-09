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

## -*- texinfo -*-
## @deftypefn {Function File} {} octapps_build @samp{optional make arguments}
##
## Runs the top-level OctApps Makefile, to e.g. build extensions.
##
## @end deftypefn

function octapps_build(varargin)
  rootdir = fullfile(fileparts(mfilename("fullpath")), "..", "..");
  system(sprintf("cd '%s' && make %s", rootdir, sprintf(" %s", varargin{:})));
endfunction

%!test
%!  octapps_build();
