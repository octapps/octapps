## Copyright (C) 2011 Karl Wette
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
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} {@var{name} =} funcName ( )
##
## Returns the name of the currently executing function.
##
## @end deftypefn

function name = funcName

  ## uses dbstack() to get the name of the
  ## calling function - see print_usage()
  stack = dbstack();
  if numel(stack) > 1
    name = stack(2).name;
  else
    ## funcName must have been called
    ## from the Octave workspace
    name = "<workspace>";
  endif

endfunction

%!function fn = __testFuncName()
%!  assert(funcName(), "__testFuncName")
%!test __testFuncName()
