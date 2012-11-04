## Copyright (C) 2011,2012 Karl Wette
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

## Inserts a reference to a Condor-defined variable in the arguments
## of a function called by a Condor job created with makeCondorJob().
## Usage:
##   var = condorVar(name)
## where
##   name = name of Condor variable.
##   var = reference to Condor variable.

function var = condorVar(name)
  assert(ischar(name));
  ## prefix with \0 so that stringify inserts literal string
  var = strcat("\0$(", name, ")");
endfunction
