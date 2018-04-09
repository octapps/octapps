## Copyright (C) 2011, 2014 Karl Wette
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
## @deftypefn {Function File} {@var{f} =} isInteractive ( )
##
## Returns whether the calling Octave script is being run from
## an interactive session, as opposed to from the command line.
## If calling function is not a script, return empty.
##
## @end deftypefn

function f = isInteractive()

  ## get filename of calling script
  stack = dbstack();
  if length(stack) > 1
    fname = stack(end).file;
    [fpath, fname, fext] = fileparts(fname);
    fname = strcat(fname, fext);

    ## if filename equals program name,
    ## script is being run from command line
    f = !strcmp(fname, program_name);

  else
    f = [];
  endif

endfunction

%!test
%!  assert(isInteractive());
