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

## Returns whether Octave is currently executing
## a script, as opposed to an interactive session
## Syntax:
##   isscript = runningAsScript

function isscript = runningAsScript

  ## get filename of function at top of stack
  stack = dbstack();
  if length(stack) > 0
    fname = stack(end).file;
  else
    fname = [];
  endif

  ## if filename equals program invocation name,
  ## we're running a script
  isscript = strcmp(fname, program_invocation_name);

endfunction
