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

## Convert UTC date strings to GPS times (using LAL functions)
## Usage:
##   gps = utc_to_gps(utc)
##   utc_to_gps utc
## where
##   gps = matrix of GPS times
##   utc = cell array of UTC date strings

function gps = utc_to_gps(utc)

  ## check input
  if ischar(utc)
    utc = {utc};
  endif
  assert(iscell(utc));

  ## load LAL
  lal;

  ## perform conversion
  gps = cellfun(@(x) XLALUTCToGPS(datevec(x)), utc, "UniformOutput", true);

endfunction


%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  assert(utc_to_gps("13-May-2005 06:13:07") == 800000000);
