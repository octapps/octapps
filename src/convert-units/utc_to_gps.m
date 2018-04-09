## Copyright (C) 2014, 2016 Karl Wette
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
## @deftypefn {Function File} { [ @var{gps}, @var{gpsns} ] =} utc_to_gps ( @var{utc} )
## @deftypefnx{Function File} {} utc_to_gps utc
##
## Convert UTC date strings to GPS times (using LAL functions)
##
## @heading Arguments
##
## @table @var
## @item gps
## matrix of GPS times (integer seconds)
##
## @item gpsns
## matrix of GPS times (nanoseconds)
##
## @item utc
## cell array of UTC date strings
##
## @end table
##
## @end deftypefn

function [gps, gpsns] = utc_to_gps(utc)

  ## check input
  if ischar(utc)
    utc = {utc};
  endif
  assert(iscell(utc));

  ## load LAL
  lal;

  ## perform conversion
  gps = gpsns = zeros(1, length(utc));
  for i = 1:length(utc)
    utci = utc{i};

    ## parse any fractional part separately and store as nanoseconds
    j = find(utci == ".");
    if !isempty(j)
      gpsns(i) = str2double(strcat("0", utci(j:end))) * 1e9;
      utci = utci(1:j-1);
    endif

    ## parse UTC string to a date vector
    if any(utci == "T")
      utcv = datevec(utci, "yyyy-mm-ddTHH:MM:SS");
    else
      utcv = datevec(utci);
    endif

    ## convert UTC date vector to a GPS time (integer seconds)
    gps(i) = double(XLALUTCToGPS(utcv));

  endfor

endfunction

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  assert(utc_to_gps("13-May-2005 06:13:07") == 800000000);
%!  [s, ns] = utc_to_gps("2011-04-24T04:25:06.123456789");
%!  assert(s == 987654321 && ns == 123456789);
