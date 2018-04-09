## Copyright (C) 2013 Karl Wette
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
## @deftypefn {Function File} {@var{total} =} histTotalCount ( @var{hgrm} )
##
## Returns the @var{total} number of counts in a histogram object.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item total
## @var{total} number of counts
##
## @end table
##
## @end deftypefn

function total = histTotalCount(hgrm)

  ## check input
  assert(isHist(hgrm));

  ## return total number of counts
  total = sum(hgrm.counts(:));

endfunction

%!test
%!  hgrm = Hist(2, {"lin", "dbin", 0.01}, {"lin", "dbin", 0.1});
%!  hgrm = addDataToHist(hgrm, [normrnd(1.7, 4.3, 13579, 1), rand(13579, 1)]);
%!  assert(histTotalCount(hgrm), 13579);
