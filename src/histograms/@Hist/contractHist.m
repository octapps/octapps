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
## @deftypefn {Function File} {@var{hgrm} =} contractHist ( @var{hgrm}, @var{newdims} )
##
## Contract a histogram by summing counts over dimensions.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item newdims
## dimensions that will remain after contraction;
## counts in other dimensions will be summed.
##
## @end table
##
## @end deftypefn

function hgrm = contractHist(hgrm, newdims)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  assert(all(1 <= newdims && newdims <= dim));
  assert(all(unique(newdims) == sort(newdims)), "Elements of 'newdims' must be unique");

  ## contract histogram bins and bin types
  hgrm.bins = hgrm.bins(newdims);
  hgrm.bintype = hgrm.bintype(newdims);

  ## sum up counts over contracted dimensions
  siz = size(hgrm.counts);
  rd = setdiff(1:dim, newdims);
  for k = 1:length(rd)
    hgrm.counts = sum(hgrm.counts, rd(k));
  endfor
  hgrm.counts = reshape(hgrm.counts, [siz(newdims), 1]);

endfunction

## test histogram contraction with Gaussian/uniform histogram
%!shared hgrm, hgrm1, hgrm2
%!  hgrm = Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1});
%!  hgrm = addDataToHist(hgrm, [normrnd(0, 1, 1e6, 1), rand(1e6, 1)]);
%!  hgrm1 = contractHist(hgrm, 1);
%!  hgrm2 = contractHist(hgrm, 2);
%!test
%!  p1 = histProbs(hgrm1); c1 = histBinGrids(hgrm1, 1, "centre");
%!  assert(mean(abs(p1 - normpdf(c1, 0, 1))) < 1e-3);
%!test
%!  p2 = histProbs(hgrm2); c2 = histBinGrids(hgrm2, 1, "centre");
%!  assert(mean(abs(p2(isfinite(c2)) - 1.0)) < 1e-2);
