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

## Shows the contents of a histogram class.
## Syntax:
##   showHist(hgrm)
## where:
##   hgrm = histogram class

function showHist(hgrm)

  ## check input
  assert(isHist(hgrm));
  dim = histDim(hgrm);

  ## get histogram bins and probability densities
  binlo = binhi = cell(1, dim);
  for k = 1:dim
    [binlo{k}, binhi{k}] = histBins(hgrm, k, "lower", "upper");
  endfor
  prob = histProbs(hgrm);

  ## get size of terminal, and set empty buffer string
  tsize = terminal_size();
  buffer = "";

  ## loop over all non-zero bins
  dims = size(prob);
  nn = find(prob(:) > 0);
  for n = 1:length(nn)

    ## get count in this bin
    [subs{1:dim}] = ind2sub(dims, nn(n));
    p = prob(subs{:});

    ## form string containing bin ranges in each dimension, and probability density
    str = "";
    for k = 1:dim
      str = strcat(str, sprintf(" [% 6g,% 6g]", binlo{k}(subs{k}), binhi{k}(subs{k})));
    endfor
    str = strcat(str, sprintf(" = %0.4e", p));

    ## if buffer would already fill terminal screen, print it and start
    ## next line with string, otherwise add string to buffer
    if length(buffer) + length(str) > tsize(2)
      printf("%s\n", buffer);
      buffer = str;
    else
      buffer = strcat(buffer, str);
    endif

  endfor

  ## if there's anything left in the buffer, print it
  if length(buffer) > 0
    printf("%s\n", buffer);
  endif

endfunction
