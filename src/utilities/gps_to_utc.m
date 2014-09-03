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

## Convert GPS times to UTC date strings (using LAL functions)
## Usage:
##   utc = gps_to_utc(gps)
##   gps_to_utc gps
## where
##   utc = cell array of UTC date strings
##   gps = matrix of GPS times

function utc = gps_to_utc(gps)

  ## check input
  if ischar(gps)
    gps = str2double(gps);
  endif
  assert(ismatrix(gps));

  ## load LAL
  lal;

  ## perform conversion
  utc = arrayfun(@(x) datestr(datenum(XLALGPSToUTC(x)(1:6))), gps, "UniformOutput", false);

endfunction


%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("*** LALSuite modules not available; skipping test ***"); return;
%!  end_try_catch
%!  assert(strcmp(gps_to_utc(800000000), "13-May-2005 06:13:07"));
