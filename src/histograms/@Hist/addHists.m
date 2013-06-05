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

## Add two histograms together. If one histogram is [],
## the other is returned.
## Syntax:
##   hgrmt = addHists(hgrm1, hgrm2)
## where:
##   hgrm{1,2} = histograms to add
##   hgrmt     = total histogram

function hgrmt = addHists(hgrm1, hgrm2)

  ## check input
  assert(nargin == 2);
  assert(isHist(hgrm1) || isHist(hgrm2), "One of hgrm{1,2} must be a valid histogram class");

  ## if one histogram is [], return the other.
  if isempty(hgrm1)
    hgrmt = hgrm2;
    return;
  elseif isempty(hgrm2)
    hgrmt = hgrm1;
    return;
  endif

  ## check histogram dimensions match
  dim = length(hgrm1.bins);
  assert(dim == length(hgrm2.bins), "Histograms hgrm{1,2} must have the same dimensionality");

  ## iterate over histogram dimensions
  newbins = cell(1, dim);
  for i = 1:dim

    ## get finite histogram bins
    bins1 = hgrm1.bins{i}(2:end-1);
    bins2 = hgrm2.bins{i}(2:end-1);

    ## get minimum bin width in to-be-added histograms
    minwidth = min([diff(bins1), diff(bins2)]);

    ## create unique, sorted array of all bins
    bins = unique([bins1, bins2]);

    ## remove any bins which would create a bin smaller
    ## than minimum bin width in to-be-added histograms
    bins([false, diff(bins) < minwidth]) = [];

    ## make sure new bins cover old bins
    bins(1) = min([bins1, bins2]);
    bins(end) = max([bins1, bins2]);

    ## set total histogram bins for this dimension
    newbins{i} = bins;

  endfor

  ## resample 1st histogram to total histogram bins to create total histogram
  hgrmt = resampleHist(hgrm1, newbins{:});

  ## resample 2nd histogram to total histogram bins
  hgrm2 = resampleHist(hgrm2, newbins{:});

  ## add counts
  hgrmt.counts += hgrm2.counts;

endfunction


%!test
%! hgrm1 = addDataToHist(Hist(1, 0:12), 0.5 + (0:11)');
%! hgrm2 = addDataToHist(Hist(1, 0:3:12), 0.5 + (0:11)');
%! hgrmt = addHists(hgrm1, hgrm2);
%! p = histProbs(hgrmt);
%! assert(length(p) == 14 && p(2:end-1) == 1/12);
