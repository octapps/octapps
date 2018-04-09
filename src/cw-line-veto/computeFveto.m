## Copyright (C) 2013 Reinhard Prix
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
## @deftypefn {Function File} {@var{Fveto} =} computeFveto ( @var{inFstats} )
##
## compute "F+veto" stat from input vector with columns [2F, 2F_1, 2F_2, ...]
## vetoed candidates are set to Fveto=-1, otherwise Fveto>=0
##
## F+veto is defined as F+veto = @{ 2F  if 2F > max(2F_1, 2F_2,...); -1 otherwise @}
##
## @end deftypefn

function Fveto = computeFveto ( inFstats )

  [ numDraws, numRows ] = size ( inFstats );
  numDet = numRows - 1;

  twoF = inFstats(:,1);
  twoFmax = max ( inFstats(:, 2:end)' )';

  veto = find ( twoF < twoFmax );

  Fveto = twoF;
  Fveto(veto) = -1;     ## allow to remove those completely from stats

  return;

endfunction

%!assert(computeFveto([10, 6, 5]), 10, 1e-3)
%!assert(computeFveto([10, 10, 5]), 10, 1e-3)
%!assert(computeFveto([10, 6, 11]), -1, 1e-3)
