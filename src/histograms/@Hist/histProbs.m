## Copyright (C) 2010 Karl Wette
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
## @deftypefn {Function File} {@var{prob} =} histProbs ( @var{hgrm} )
## @deftypefnx{Function File} {@var{fprob} =} histProbs ( @var{hgrm}, @code{finite} )
##
## Return the probabily densities of each histogram bin
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item prob
## probability densities of all bins
##
## @item fprob
## probability densities of @code{finite} bins
##
## @end table
##
## @end deftypefn

function prob = histProbs(hgrm, finite = [])

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  assert(isempty(finite) || strcmp(finite, "finite"));

  ## start with counts and normalise by total count
  prob = hgrm.counts;
  norm = sum(prob(:));
  if norm > 0
    prob ./= norm;
  endif

  ## compute areas of all probability bins
  areas = ones(size(prob));
  for k = 1:dim
    dbins = histBinGrids(hgrm, k, "width");
    areas .*= dbins;
  endfor

  ## determine which bins have non-zero area
  nzii = (areas > 0);

  ## further normalise each probability bin by its area,
  ## so bins with different areas are treated correctly
  prob(nzii) ./= areas(nzii);

  ## if requested, return only probability densities of finite bins
  if !isempty(finite)
    ii = cellfun(@(x) 2:length(x)-2, hgrm.bins, "UniformOutput", false);
    prob = prob(ii{:});
  endif

endfunction

## generate Gaussian histograms and test normalisation with equal/unequal bins
%!shared hgrm1, hgrm2
%!  hgrm1 = Hist(1, {"lin", "dbin", 0.01});
%!  hgrm1 = addDataToHist(hgrm1, normrnd(0, 1, 1e6, 1));
%!  hgrm2 = Hist(1, {"log", "minrange", 0.5, "binsper10", 50});
%!  hgrm2 = addDataToHist(hgrm2, normrnd(0, 1, 1e6, 1));
%!test
%!  p1 = histProbs(hgrm1); c1 = histBinGrids(hgrm1, 1, "centre");
%!  assert(mean(abs(p1 - normpdf(c1, 0, 1))) < 0.005);
%!test
%!  p2 = histProbs(hgrm2); c2 = histBinGrids(hgrm2, 1, "centre");
%!  assert(mean(abs(p2 - normpdf(c2, 0, 1))) < 0.005);

## test return of finite bin probability densities
%!shared hgrm3
%!  hgrm3 = Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1});
%!  hgrm3 = addDataToHist(hgrm3, rand(1e6, 2));
%!test
%!  prob = histProbs(hgrm3);
%!  fprob = histProbs(hgrm3, "finite");
%!  assert(all(all(prob(2:end-1, 2:end-1) == fprob)));
