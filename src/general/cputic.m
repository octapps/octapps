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
## @deftypefn {Function File} {} cputic ( @code{name} )
## @deftypefnx{Function File} {@var{t} =} cputic ( @code{name} )
##
## Sets or retrieves the value of a named CPU time counter.
##
## @end deftypefn

function varargout = cputic(name)

  ## table of CPU time counters
  persistent cputic_counters = [];

  ## check input and output arguments
  assert(ischar(name));
  assert(nargout <= 1);

  ## find index of named counter, or empty if it doesn't exist
  if !isempty(cputic_counters)
    i = find(strcmp(name, {cputic_counters.name}));
  else
    i = [];
  endif

  if nargout > 0

    ## retrieves the counter, or error if it doesn't exist
    if isempty(i)
      error("%s: unknown CPU time counter '%s'", funcName, name);
    else
      varargout = {cputic_counters(i).t};
    endif

  else

    ## set the counter, creating a new one if it doesn't exist
    if isempty(i)
      i = length(cputic_counters) + 1;
    endif
    cputic_counters(i).t = cputime();
    cputic_counters(i).name = name;

  endif

endfunction

%!test
%!  cputic("__test");
