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
## @deftypefn {Function File} {@var{utc} =} gps_to_utc ( @var{gps} )
## @deftypefnx{Function File} {} gps_to_utc @var{gps}
##
## Convert GPS times to UTC date strings (using LAL functions)
##
## @heading Arguments
##
## @table @var
## @item utc
## cell array of UTC date strings (or a single string)
##
## @item gps
## matrix of GPS times
##
## @end table
##
## @end deftypefn

function utc = gps_to_utc(gps)

  ## check input
  if ischar(gps)
    gps = str2double(gps);
  endif
  assert(ismatrix(gps));

  ## load LAL
  lal;

  ## perform conversion
  utc = cell(1, length(gps));
  for i = 1:length(gps)

    ## convert GPS time to a UTC date vector
    utcv = XLALGPSToUTC(gps(i));

    ## convert UTC date vector to a string
    utc{i} = datestr(datenum(utcv(1:6)));

  endfor

  ## check output
  if length(utc) == 1
    utc = utc{1};
  endif

endfunction

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  assert(strcmp(gps_to_utc(800000000), "13-May-2005 06:13:07"));
