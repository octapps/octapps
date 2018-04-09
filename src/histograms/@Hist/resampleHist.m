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
## @deftypefn {Function File} {@var{hgrm} =} resampleHist ( @var{hgrm}, @var{k}, @var{newbins_k} )
## @deftypefnx{Function File} {@var{hgrm} =} resampleHist ( @var{hgrm}, @var{newbins_1}, @dots{}, @var{newbins_dim} )
##
## Resamples a histogram to a new set of bins
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item k
## dimension along which to resample
##
## @item newbins_k
## new bins in dimension @var{k} (dim = number of dimensions)
##
## @end table
##
## @end deftypefn

function hgrm = resampleHist(hgrm, varargin)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);

  ## if all arguments are not scalars, and
  ## number of arguments equal to number of dimensions,
  ## take each arguments as new bins in k dimensions
  if all(cellfun(@(x) !isscalar(x), varargin))
    if length(varargin) != dim
      error("Number of new bin vectors must match number of dimensions");
    endif

    ## loop over dimensions
    for k = 1:dim
      hgrm = resampleHist(hgrm, k, varargin{k});
    endfor

  else

    ## otherwise intepret arguments as [k, newbins]
    if length(varargin) != 2
      error("Invalid input arguments!");
    endif
    [k, newbins] = deal(varargin{:});
    assert(isscalar(k));
    newbins = reshape(sort(newbins(isfinite(newbins))), 1, []);

    ## get old (finite) bin boundaries
    bins = hgrm.bins{k}(2:end-1);

    ## is old histogram has no finite bins
    if isempty(bins)

      hgrm.bins{k} = [-inf, newbins, inf];
      assert(all(hgrm.counts(:) == 0));
      siz = cellfun(@(x) length(x)-1, hgrm.bins);
      if length(siz) == 1
        siz(2) = 1;
      endif
      hgrm.counts = zeros(siz);

    else

      ## round bin boundaries
      [bins, newbins] = roundHistBinBounds(bins, newbins);

      ## check that new bins cover the range of old bins
      if !(min(newbins) <= min(bins)) || !(max(newbins) >= max(bins))
        error("Range of new bins (%g to %g) does not include old bins (%g to %g)!",
              min(newbins), max(newbins), min(bins), max(bins));
      endif

      ## permute dimension k to beginning of array,
      ## then flatten other dimensions
      counts = hgrm.counts;
      perm = [k 1:(k-1) (k+1):max(dim,length(size(counts)))];
      counts = permute(counts, perm);
      siz = size(counts);
      counts = reshape(counts, siz(1), []);

      ## remove first (-inf) and last (inf) rows
      minfcounts = counts(1, :);
      pinfcounts = counts(end, :);
      counts = counts(2:end-1, :);

      ## if new bins are a superset of old bins, no
      ## resampling is required - just need to extend
      ## probability array with zeros
      newbins_ss = newbins(min(bins) <= newbins & newbins <= max(bins));
      if length(newbins_ss) == length(bins) && all(newbins_ss == bins)
        nloz = length(newbins(newbins < min(bins)));
        nhiz = length(newbins(newbins > max(bins)));
        newcounts = [zeros(nloz, size(counts, 2));
                     counts;
                     zeros(nhiz, size(counts, 2))];
      else
        ## otherwise, need to interpolate
        ## probabilities to new bins
        lowbin = bins(1:end-1);
        dbins = diff(bins);
        dnewbins = diff(newbins);

        ## calculate probabilities along dimension k
        prob = counts .* dbins(:)(:,ones(size(counts, 2), 1));

        ## create cumulative probability array resampled over new bins
        cumprob = zeros(length(newbins), size(counts, 2));
        for i = 1:length(newbins)

          ## decide what fraction of each old bin
          ## should contribute to new bin
          fr = (newbins(i) - lowbin) ./ dbins;
          fr(fr < 0) = 0;
          fr(fr > 1) = 1;

          ## assign cumulative probability to new bin
          cumprob(i,:) = sum(prob .* fr(:)(:,ones(size(counts, 2), 1)), 1);

        endfor

        ## calculate new probability array from cumulative probabilities
        newcounts = (cumprob(2:end,:) - cumprob(1:end-1,:)) ./ dnewbins(:)(:,ones(size(counts, 2), 1));

      endif

      ## add back first (-inf) and last (inf) rows
      newcounts = [minfcounts; newcounts; pinfcounts];

      ## unflatten other dimensions, then
      ## restore original dimension order
      siz(1) = size(newcounts, 1);
      newcounts = reshape(newcounts, siz);
      newcounts = ipermute(newcounts, perm);

      ## resampled histogram
      hgrm.bins{k} = [-inf, newbins, inf];
      hgrm.counts = newcounts;

    endif

  endif

endfunction

## Round given histogram bins boundaries to within a small
## fraction of the smallest overall bin size, so that one
## can compare floating-point precision bin boundaries robustly.
function varargout = roundHistBinBounds(varargin)
  assert(nargin == nargout);
  dbins = min(cell2mat(cellfun(@(b) min(diff(unique(b))), varargin, "UniformOutput", false)));
  dbins = 10^(floor(log10(dbins)) - 3);
  varargout = cellfun(@(b) unique(round(b / dbins) * dbins), varargin, "UniformOutput", false);
endfunction

%!test
%!  hgrm = Hist(2, {"lin", "dbin", 0.01}, {"lin", "dbin", 0.1});
%!  hgrm = addDataToHist(hgrm, [normrnd(1.7, 4.3, 1e6, 1), rand(1e6, 1)]);
%!  assert(meanOfHist(hgrm, 1), meanOfHist(resampleHist(hgrm, 1, -30:0.2:30), 1), 1e-3);
