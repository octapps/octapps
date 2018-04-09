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
## @deftypefn {Function File} {} cputoc ( @code{name} ) ;
##
## Prints the elapsed CPU time since a named CPU time counter was set.
##
## @end deftypefn

function cputoc(name)

  ## check input arguments
  assert(ischar(name));

  ## get CPU time now and at last counter set
  t = cputime();
  t0 = cputic(name);

  ## print elapsed CPU time, without paging
  page_screen_output(0, "local");
  printf("Elapsed CPU time for counter '%s' = %0.3f\n", name, t - t0);

endfunction

%!test
%!  cputic("__test");
%!  cputoc("__test");
