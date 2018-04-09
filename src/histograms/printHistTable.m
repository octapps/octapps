## Copyright (C) 2010, 2016 Karl Wette
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
## @deftypefn {Function File} {} printHistTable ( @var{hgrm}, @var{opt}, @var{val}, @dots{} )
##
## Print the contents of a histogram object as an ASCII table.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @end table
##
## @heading and options are
##
## @table @var
## @item dbins
## width of bins to use in each dimension
##
## @item pth
## threshold to apply before printing
##
## @end table
##
## @end deftypefn

function printHistTable(hgrm, varargin)

  ## check input
  parseOptions(varargin,
               {"dbins", "real,strictpos,vector", []},
               {"pth", "real,strictunit,scalar", 1e-3},
               []);
  assert(isa(hgrm, "Hist"));
  dim = histDim(hgrm);

  ## threshold and restrict histogram
  hgrm = restrictHist(thresholdHist(hgrm, pth));

  ## resample histogram to given bin widths
  if !isempty(dbins)
    assert(length(dbins) == dim, "%s: length of 'dbins' must match histogram dimension", funcName);
    newbins = {};
    frng = histRange(hgrm, "finite");
    for k = 1:dim
      newbins{k} = frng(k, 1) + (0:ceil(range(frng(k, :)) / dbins(k))) * dbins(k);
    endfor
    hgrm = resampleHist(hgrm, newbins{:});
  endif

  ## get histogram bins and probability densities
  binlo = binhi = cell(1, dim);
  for k = 1:dim
    [binlo{k}, binhi{k}] = histBins(hgrm, k, "lower", "upper");
  endfor
  prob = histProbs(hgrm);

  ## print ASCII table header
  for k = 1:dim
    printf("# columns %i, %i: bin boundaries for dimension %i\n", 2*k - 1, 2*k, k);
  endfor
  printf("# column %i: probability density\n", 2*k + 1);

  ## loop over all non-zero bins
  dims = size(prob);
  nn = find(prob(:) > 0);
  for n = 1:length(nn)

    ## get count in this bin
    [subs{1:dim}] = ind2sub(dims, nn(n));
    p = prob(subs{:});

    ## print bin ranges in each dimension
    for k = 1:dim
      printf(" % -8.4g % -8.4g", binlo{k}(subs{k}), binhi{k}(subs{k}));
    endfor

    ## print probability density
    printf(" %8.4e\n", p);

  endfor

endfunction

%!test
%!  hgrm = Hist(2, {"lin", "dbin", 0.01}, {"lin", "dbin", 0.1});
%!  hgrm = addDataToHist(hgrm, [normrnd(1.7, 4.3, 1e6, 1), rand(1e6, 1)]);
%!  showHist(hgrm);
