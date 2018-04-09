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
## @deftypefn {Function File} {} showHist ( @var{hgrm} )
##
## Show the contents of a histogram object.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @end table
##
## @end deftypefn

function s = showHist(hgrm)

  ## check input
  assert(isa(hgrm, "Hist"));
  dim = histDim(hgrm);

  ## get histogram bins and probability densities
  binlo = binhi = cell(1, dim);
  for k = 1:dim
    [binlo{k}, binhi{k}] = histBins(hgrm, k, "lower", "upper");
  endfor
  prob = histProbs(hgrm);

  ## loop over all non-zero bins
  strs = {};
  dims = size(prob);
  nn = find(prob(:) > 0);
  for n = 1:length(nn)

    ## get count in this bin
    [subs{1:dim}] = ind2sub(dims, nn(n));
    p = prob(subs{:});

    ## form string containing bin ranges in each dimension, and probability density
    strs{n} = "";
    for k = 1:dim
      strs{n} = strcat(strs{n}, sprintf("[%g,%g]", binlo{k}(subs{k}), binhi{k}(subs{k})));
    endfor
    strs{n} = strcat(strs{n}, sprintf(" = %0.4e", p));

  endfor

  ## print strings describing each non-zero bin, in columns
  printf("{\n%s}\n", list_in_columns(strs, [], "  "));

endfunction

%!test
%!  hgrm = createGaussianHist(1.2, 3.4, "binsize", 0.1);
%!  showHist(hgrm);
