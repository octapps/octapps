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
## @deftypefn {Function File} {@var{rng} =} CreateRandParam ( @var{p}, @var{p}, @dots{} )
##
## Parses random parameters specs, which may be either
## @itemize
## @item @samp{constant}:
## denoting a single value, or
## @item [@samp{min}, @samp{max}]:
## denoting a range of values
## @end itemize
##
## @heading Arguments
##
## @table @var
## @item rng
## random parameter generator
##
## @item p
## random parameter spec
##
## @end table
##
## @end deftypefn

function rng = CreateRandParam(varargin)

  ## load GSL wrappers
  gsl;

  ## initial indexes of random and constant parameters
  rng.rii = rng.rm = rng.rc = rng.cii = rng.cc = [];

  ## iterate over parameters
  for i = 1:nargin
    p = varargin{i};
    switch numel(p)
      case 1    ## <constant>
        rng.cii(end+1,1) = i;
        rng.cc(end+1,1) = p;
      case 2    ## [<min>, <max>]
        rng.rii(end+1,1) = i;
        rng.rm(end+1,1) = max(p) - min(p);
        rng.rc(end+1,1) = min(p);
      otherwise
        error("Invalid random parameter spec!");
    endswitch
  endfor

  ## create quasi-random number generator if needed
  if length(rng.rii) > 0
    rng.q = new_gsl_qrng("halton", length(rng.rii));
  endif
  rng.allconst = (length(rng.rii) == 0);

endfunction

%!assert(isstruct(CreateRandParam([0, 5.5], [2.2, 7])))
