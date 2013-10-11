## Copyright (C) 2011, 2013 Karl Wette
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

## Transform the bins of a histogram.
## Syntax:
##   hgrm = transformHistBins(hgrm, F)
## where:
##   hgrm = histogram class
##   F    = function to apply to bins:
##          - should accept column vectors as inputs and return
##            an array whose columns are vectorised outputs
##          - number of input/output arguments must match
##            histogram dimensionality

function hgrm = transformHistBins(hgrm, F)

  ## check input
  assert(isHist(hgrm));
  assert(is_function_handle(F));
  dim = length(hgrm.bins);

  ## load GSL module, and create quasi-random number generator
  gsl;
  qrng = new_gsl_qrng("halton", dim);

  ## get histogram bins and counts as column vectors
  lo = hi = cell(1, dim);
  for k = 1:dim
    lo{k} = reshape(histBinGrids(hgrm, k, "lower"), [], 1);
    hi{k} = reshape(histBinGrids(hgrm, k, "upper"), [], 1);
  endfor
  counts = reshape(hgrm.counts, [], 1);

  ## zero out histogram contents
  hgrm.counts = zeros(size(hgrm.counts));

  ## loop over non-zero counts
  ii = reshape(find(counts > 0), 1, []);
  for i = ii

    ## get quasi-random numbers for each count
    qrng.reset();
    r = qrng.get(counts(i));
    assert(size(r) == [dim, counts(i)]);

    ## generate data samples for function
    Fargs = cell(1, dim);
    for k = 1:dim
      switch hgrm.bintype{k}.name

        case "log"   ## logarithmic bins
          l = log10(abs(lo{k}(i)) + eps);
          h = log10(abs(hi{k}(i)) + eps);
          s = sign(0.5*(lo{k}(i) + hi{k}(i)));
          x = s .* 10.^( l + (h - l).*r(k,:) );

        otherwise   ## assume linear bins
          l = lo{k}(i);
          h = hi{k}(i);
          x = l + (h - l).*r(k,:);

      endswitch
      Fargs{k} = reshape(x, [], 1);
    endfor

    ## transform data samples
    Fout = F(Fargs{:});
    assert(ismatrix(Fout));
    assert(size(Fout) == [counts(i), dim]);

    ## add data to histogram
    hgrm = addDataToHist(hgrm, Fout);

  endfor

endfunction

## create 1-D histograms for testing
%!shared hgrmA, hgrmA1, hgrmA2, hgrmA3
%! hgrmA = hgrmA1 = hgrmA2 = hgrmA3 = Hist(1, {"lin", "dbin", 0.1});
%! N = 1e6;
%! do
%!   x = randn(N, 1);
%!   oldhgrmA = hgrmA;
%!   hgrmA = addDataToHist(hgrmA, x);
%!   hgrmA1 = addDataToHist(hgrmA1, abs(x));
%!   hgrmA2 = addDataToHist(hgrmA2, x.^2 - 3);
%!   hgrmA3 = addDataToHist(hgrmA3, sin(x));
%!   err = histDistance(oldhgrmA, hgrmA);
%! until err < 1e-2

## test 1-D histograms
%!test
%! t_hgrmA = transformHistBins(hgrmA, @(x) x);
%! t_hgrmA1 = transformHistBins(hgrmA, @(x) abs(x));
%! t_hgrmA2 = transformHistBins(hgrmA, @(x) x.^2 - 3);
%! t_hgrmA3 = transformHistBins(hgrmA, @(x) sin(x));
%! assert(histDistance(hgrmA, t_hgrmA) < 1e-4);
%! assert(histDistance(hgrmA1, t_hgrmA1) < 0.05);
%! assert(histDistance(hgrmA2, t_hgrmA2) < 0.05);
%! assert(histDistance(hgrmA3, t_hgrmA3) < 0.05);

## create 2-D histograms for testing
%!shared hgrmB, hgrmB1, hgrmB2, hgrmB3
%! hgrmB = hgrmB1 = hgrmB2 = hgrmB3 = Hist(2, {"lin", "dbin", 0.1}, {"log", "minrange", 1.0, "binsper10", 8});
%! N = 1e6;
%! do
%!   x = randn(N, 1);
%!   y = sign(x) .* 10.^(-1 + 3*rand(N, 1));
%!   oldhgrmB = hgrmB;
%!   hgrmB = addDataToHist(hgrmB, [x, y]);
%!   hgrmB1 = addDataToHist(hgrmB1, [abs(x), 10.*y]);
%!   hgrmB2 = addDataToHist(hgrmB2, [x.^2 - 3, y.^3]);
%!   hgrmB3 = addDataToHist(hgrmB3, [sin(x), cos(y)]);
%!   err = histDistance(oldhgrmB, hgrmB);
%! until err < 1e-2

## test 2-D histograms
%!test
%! t_hgrmB = transformHistBins(hgrmB, @(x,y) [x, y]);
%! t_hgrmB1 = transformHistBins(hgrmB, @(x,y) [abs(x), 10.*y]);
%! t_hgrmB2 = transformHistBins(hgrmB, @(x,y) [x.^2 - 3, y.^3]);
%! t_hgrmB3 = transformHistBins(hgrmB, @(x,y) [sin(x), cos(y)]);
# %! assert(histDistance(hgrmB, t_hgrmB) < 1e-4);
# %! assert(histDistance(hgrmB1, t_hgrmB1) < 0.05);
# %! assert(histDistance(hgrmB2, t_hgrmB2) < 0.05);
# %! assert(histDistance(hgrmB3, t_hgrmB3) < 0.05);
