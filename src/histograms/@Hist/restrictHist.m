## Copyright (C) 2015 Karl Wette
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
## @deftypefn {Function File} {@var{rhgrm} =} restrictHist ( @var{hgrm}, @var{k}, [ @var{xl_k}, @var{xh_k} ] )
## @deftypefnx{Function File} {@var{rhgrm} =} restrictHist ( @var{hgrm}, [ @var{xl_1}, @var{xh_1} ] , @dots{}, [ @var{xl_dim}, @var{xh_dim} ] )
## @deftypefnx{Function File} {@var{rhgrm} =} restrictHist ( @var{hgrm} )
## @deftypefnx{Function File} {@var{rhgrm} =} restrictHist ( @dots{}, @var{discard} )
##
## Extract histogram restricted to subrange of bins, as determined by
## the ranges [@var{xl_k}, @var{xh_k}]. Samples outside of these ranges are moved
## to the histogram boundary bins [-\inf,@var{xl_k}] and [@var{xh_k},\inf], unless
## the string "@var{discard}" is given as the last argument. If no ranges are
## given, @command{histRange()} is used to find the minimum ranges.
##
## @heading Arguments
##
## @table @var
## @item rhgrm
## restricted histogram object
##
## @item hgrm
## original histogram object
##
## @item k
## dimension along which to restrict histogram range
##
## @item xl_k
## @itemx xh_k
## range in dimension @var{k} to restrict range to
##
## @end table
##
## @end deftypefn

function hgrm = restrictHist(hgrm, varargin)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  if length(varargin) > 0 && strcmp(varargin{end}, "discard")
    discard = varargin(end);
    varargin = varargin(1:end-1);
  else
    discard = {};
  endif

  if length(varargin) == 0

    ## if no range arguments are given, use histRange()
    for k = 1:dim
      range_k = histRange(hgrm, k);
      hgrm = restrictHist(hgrm, k, range_k, discard{:});
    endfor

  elseif length(varargin) == dim && all(cellfun(@(x) !isscalar(x), varargin))

    ## if all arguments are not scalars, and number of arguments equals
    ## number of dimensions, take each arguments as new bins in k dimensions
    if length(varargin) != dim
      error("Number of new bin vectors must match number of dimensions");
    endif
    for k = 1:dim
      hgrm = restrictHist(hgrm, k, varargin{k}, discard{:});
    endfor

  elseif length(varargin) == 2

    ## otherwise intepret arguments as {k, [xl_k, xh_k]}
    [k, xlh] = deal(varargin{:});
    assert(isscalar(k));
    assert(length(xlh) == 2);
    xl = xlh(1);
    xh = xlh(2);
    clear xlh;
    assert(xl < xh);

    ## set infinite bin limits to largest finite bin
    bins = hgrm.bins{k};
    if isinf(xl)
      xl = bins(2);
    endif
    if isinf(xh)
      xh = bins(end-1);
    endif

    ## resample histogram to ensure bin boundaries at range boundaries
    hgrm = resampleHist(hgrm, k, unique([bins, xl, xh]));
    bins = hgrm.bins{k};

    ## permute dimension k to beginning of array, then flatten other dimensions
    counts = hgrm.counts;
    perm = [k 1:(k-1) (k+1):max(dim,length(size(counts)))];
    counts = permute(counts, perm);
    siz = size(counts);
    counts = reshape(counts, siz(1), []);

    ## get indices of counts which are below, within, and above range
    iil = find(bins(1:end-1) < xl);
    iih = find(bins(2:end) > xh);
    iim = (max(iil)+1):(min(iih-1));

    ## sum counts below and above range, keep counts within range
    assert(size(counts, 1) + 1 == length(bins));
    counts = [sum(counts(iil, :), 1); counts(iim, :); sum(counts(iih, :), 1)];
    bins = [-inf, bins(xl <= bins & bins <= xh), inf];
    assert(size(counts, 1) + 1 == length(bins));

    ## discard counts in infinite bins, if desired
    if !isempty(discard)
      counts(1, :) = 0;
      counts(end, :) = 0;
    endif

    ## unflatten other dimensions, then restore original dimension order
    siz(1) = size(counts, 1);
    counts = reshape(counts, siz);
    counts = ipermute(counts, perm);

    ## restricted histogram
    hgrm.counts = counts;
    hgrm.bins{k} = bins;

  else
    error("Invalid input arguments!");
  endif

endfunction

%!test
%!  hgrm = Hist(2, {"lin", 0.01}, {"lin", 0.01});
%!  hgrm = addDataToHist(hgrm, rand(50000,2));
%!  hgrmx = restrictHist(hgrm, 1, [0, 0.5]);
%!  hgrmy = restrictHist(hgrm, 2, [0, 0.3]);
%!  assert(abs(meanOfHist(contractHist(hgrm, 1)) - 0.5) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrm, 2)) - 0.5) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrmx, 1)) - 0.25) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrmx, 2)) - 0.5) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrmy, 1)) - 0.5) < 1e-2);
%!  assert(abs(meanOfHist(contractHist(hgrmy, 2)) - 0.15) < 1e-2);

%!test
%!  hgrm = Hist(2, -1.0:0.1:2.0, -1.0:0.1:2.0);
%!  hgrm = addDataToHist(hgrm, rand(50000,2));
%!  count = histTotalCount(hgrm);
%!  hgrmx = restrictHist(hgrm, 1, [0.0, 1.0]);
%!  hgrmy = restrictHist(hgrm, 2, [-0.5, 1.5]);
%!  hgrmxy = restrictHist(hgrm, [0, 0.5], [0, 0.5]);
%!  assert(histTotalCount(hgrmx) == count);
%!  assert(histTotalCount(hgrmy) == count);
%!  assert(histTotalCount(hgrmxy) == count);
