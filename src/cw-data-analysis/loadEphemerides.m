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

## Load Earth and Sun ephemerides from LALPulsar.
## Syntax:
##   ephemerides = loadEphemerides("opt", val, ...)
## where:
##   ephemerides = structure containing ephemerides
## Options:
##   "earth_file": Earth ephemerides file (default: earth00-19-DE405.dat.gz)
##   "sun_file": Sun ephemerides file (default: sun00-19-DE405.dat.gz)

function ephemerides = loadEphemerides(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"earth_file", "char", "earth00-19-DE405.dat.gz"},
               {"sun_file", "char", "sun00-19-DE405.dat.gz"},
               []);

  ## use pre-loaded default ephemerides
  global default_ephemerides;
  if length(varargin) == 0 && !isempty(default_ephemerides)
    ephemerides = default_ephemerides;
    return
  endif

  ## load ephemerides
  try
    ephemerides = XLALInitBarycenter(earth_file, sun_file);
  catch
    error("%s: Could not load ephemerides", funcName);
  end_try_catch

  ## store pre-loaded default ephemerides
  if length(varargin) == 0 && isempty(default_ephemerides)
    default_ephemerides = ephemerides;
  endif

endfunction


%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!
%!  ephemerides = loadEphemerides();
%!  ephemerides = loadEphemerides();
%!  ephemerides = loadEphemerides();
