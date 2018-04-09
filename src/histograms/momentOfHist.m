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
## @deftypefn {Function File} {@var{mu} =} momentOfHist ( @var{hgrm}, @var{sumdims}, @var{n}, [ @var{x0} = 0 ] )
##
## Computes the moments of a histogram:
## Only moments for finite bins are returned.
##
## @heading Arguments
##
## @table @var
## @item mu
## integral over x@{sumdims=sd@} of
## p(x@{sd(1)@},...,x@{sd(end)@})
## * (x@{sd(1)@}-@var{x0}@{sd(1)@})^@var{n}@{sd(1)@}
## * @dots{}
## * (x@{sd(end)@}-@var{x0}@{sd(end)@})^@var{n}@{sd(end)@} dx@{sd(1)@} ... dx@{sd(end)@}
##
## @item hgrm
## histogram object
##
## @item sumdims
## dimensions to be summed over
##
## @item n
## moment orders in each summed dimension
##
## @item x0
## bin offsets, must either be a scalar or match the sizes
## of the histogram dimensions *not* being summed over
##
## @end table
##
## @end deftypefn

function mu = momentOfHist(hgrm, sumdims, n, x0 = 0)

  ## check input
  assert(isa(hgrm, "Hist"));
  dim = histDim(hgrm);
  assert(all(1 <= sumdims && sumdims <= dim));
  assert(all(unique(sumdims) == sort(sumdims)), "Elements of 'sumdims' must be unique");
  assert(isvector(n) && length(n) == length(sumdims) && all(n >= 0));

  ## get histogram probability densities of finite bins
  mu = norm = histProbs(hgrm, "finite");

  ## check size of bin offsets, then replicate to correct size
  siz = size(mu);
  rd = setdiff(1:dim, sumdims);
  if isscalar(x0)
    x0 *= ones(siz);
  else
    if length(rd) == 1
      assert(numel(x0) == siz(rd));
    else
      assert(all(size(x0) == siz(rd)));
    endif
    x0 = replOver(x0, sumdims, siz);
  endif

  ## loop over summed dimensions
  for i = 1:length(sumdims)

    ## get lower and upper bin boundaries
    [xl, xh] = histBinGrids(hgrm, sumdims(i), "finite", "lower", "upper");

    ## multiply probability densities by integral term for ith summed dimension
    nip1 = n(i) + 1;
    mu .*= ( (xh - x0).^nip1 - (xl - x0).^nip1 ) ./ nip1;

    ## calculate normalisation
    norm .*= xh - xl;

  endfor

  ## sum moments and norm over given dimensions
  for k = 1:length(sumdims)
    mu = sum(mu, sumdims(k));
    norm = sum(norm, sumdims(k));
  endfor
  mu = squeeze(mu);
  norm = squeeze(norm);

  ## normalise moments
  mu ./= norm;

endfunction

%!shared hgrm
%!  hgrm = createGaussianHist(1.2, 3.4, "binsize", 0.1);
%!assert(momentOfHist(hgrm, 1, 0), 1.0, 1e-3)
%!assert(momentOfHist(hgrm, 1, 1), 1.2, 1e-3)
%!assert(momentOfHist(hgrm, 1, 2, 1.2), 3.4.^2, 1e-3)
%!assert(momentOfHist(hgrm, 1, 3, 1.2), 0.0, 1e-3)
