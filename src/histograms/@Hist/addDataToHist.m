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
## @deftypefn {Function File} {@var{hgrm} =} addDataToHist ( @var{hgrm}, @var{data} )
##
## Adds the given input @var{data} to the histogram.
## If the histogram is too small, more bins are added.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item data
## input histogram data
##
## @end table
##
## @end deftypefn

function hgrm = addDataToHist(hgrm, data)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  assert(ismatrix(data) && size(data, 2) == dim);

  ## return immediately if data is empty
  if isempty(data)
    return
  endif

  ## check for non-numeric data
  if any(isnan(data(:)))
    error("%s: Input data contains NaNs", funcName);
  endif

  ## expand histogram to include new bins, if needed
  for k = 1:dim

    ## get range of current (finite) bins
    bins = hgrm.bins{k}(2:end-1);
    binmin = bins(1);
    binmax = bins(end);

    ## get range of (finite) data
    finii = isfinite(data(:,k));
    datamin = min(data(finii,k));
    datamax = max(data(finii,k));

    ## if more bins are required
    if any(finii) && (datamin < binmin || datamax >= binmax)

      ## select bin type
      newbinslo = newbinshi = [];
      switch hgrm.bintype{k}.name

        case "fixed"   ## fixed bins, cannot be extended, so set data to +/- infinity
          data(data(:,k) < binmin, k) = -inf;
          data(data(:,k) >= binmax, k) = +inf;

        case "lin"   ## linear bin generator
          dbin = hgrm.bintype{k}.dbin;

          ## create new lower bins, if needed
          if datamin < binmin
            newbinslo = binmin - (ceil((binmin - datamin) / dbin):-1:1) * dbin;
          endif

          ## create new upper bins, if needed
          if datamax >= binmax
            newbinshi = binmax + (1:(1+floor((datamax - binmax) / dbin))) * dbin;
          endif

        case "log"   ## logarithmic bin generator
          binsper10 = hgrm.bintype{k}.binsper10;

          ## if no minimum bin range has been created
          if length(bins) == 1

            ## work out minimum range based on data, rounded up to nearest power of 10
            minrange = 10^ceil(log10(max(abs(datamin), abs(datamax))));

            ## create minimum bins
            newbins = linspace(-minrange, minrange, 2*binsper10 + 1);
            newbinslo = newbins(newbins < binmin);
            newbinshi = newbins(newbins > binmax);

          else

            ## extend lower bins, if needed
            r = binmin;
            while datamin < r
              r *= 10;
              binslo = linspace(r, 0, binsper10 + 1);
              binslo = binslo(binslo < binmin);
              newbinslo = [binslo, newbinslo];
              binmin = newbinslo(1);
            endwhile

            ## extend upper bins, if needed
            r = binmax;
            while datamax >= r
              r *= 10;
              binshi = linspace(0, r, binsper10 + 1);
              binshi = binshi(binshi > binmax);
              newbinshi = [newbinshi, binshi];
              binmax = newbinshi(end);
            endwhile

          endif

        otherwise
          error("%s: unknown bin type '%s'", funcName, hgrm.bintype{k}.name)

      endswitch
      assert(!isempty(newbinslo) || !isempty(newbinshi));

      ## resize histogram
      hgrm = resampleHist(hgrm, k, [newbinslo, bins, newbinshi]);

    endif

  endfor

  ## generate bin indices
  ii = zeros(size(data));
  for k = 1:dim
    datak = data(:,k);

    ## so that last (finite) bin is treated as <=
    if length(hgrm.bins{k}) > 3
      datak(datak == hgrm.bins{k}(end-1)) = hgrm.bins{k}(end-2);
    endif

    ## lookup indices
    ii(:,k) = lookup(hgrm.bins{k}, datak, "lr");

  endfor

  ## multiplicities of each bin index
  ii = sortrows(ii);
  [ii, nnii] = unique(ii, "rows", "last");
  nn = diff([0; nnii]);

  ## add bin multiplicities to correct bins
  jj = mat2cell(ii, size(ii, 1), ones(length(hgrm.bins), 1));
  hgrm.counts(sub2ind(size(hgrm.counts), jj{:})) += nn;

endfunction

%!assert(histBins(addDataToHist(Hist(1, {"lin", "dbin", 1}), -2), 1, "finite", "bins")', -2:0)
%!assert(histBins(addDataToHist(Hist(1, {"lin", "dbin", 1}), -1), 1, "finite", "bins")', -1:0)
%!assert(histBins(addDataToHist(Hist(1, {"lin", "dbin", 1}),  0), 1, "finite", "bins")',  0:1)
%!assert(histBins(addDataToHist(Hist(1, {"lin", "dbin", 1}),  1), 1, "finite", "bins")',  0:2)
%!assert(histBins(addDataToHist(Hist(1, {"lin", "dbin", 1}),  2), 1, "finite", "bins")',  0:3)

%!assert(histProbs(addDataToHist(Hist(1, {"lin", "dbin", 1}), -2), "finite")', [1 0])
%!assert(histProbs(addDataToHist(Hist(1, {"lin", "dbin", 1}), -1), "finite")', [1])
%!assert(histProbs(addDataToHist(Hist(1, {"lin", "dbin", 1}),  0), "finite")', [1])
%!assert(histProbs(addDataToHist(Hist(1, {"lin", "dbin", 1}),  1), "finite")', [0 1])
%!assert(histProbs(addDataToHist(Hist(1, {"lin", "dbin", 1}),  2), "finite")', [0 0 1])

%!assert(histBins(addDataToHist(Hist(1, {"log", "binsper10", 1}), 0.9), 1, "finite", "bins")', -1:1, 1e-6)
%!assert(histBins(addDataToHist(Hist(1, {"log", "binsper10", 10}), 0.9), 1, "finite", "bins")', -1:0.1:1, 1e-6)
%!assert(histBins(addDataToHist(Hist(1, {"log", "minrange", 1, "binsper10", 10}), 0.9), 1, "finite", "bins")', -1:0.1:1, 1e-6)
%!assert(histBins(addDataToHist(Hist(1, {"log", "minrange", 1, "binsper10", 10}), 1.1), 1, "finite", "bins")', [-1:0.1:1, 2:10], 1e-6)
%!assert(histBins(addDataToHist(Hist(1, {"log", "minrange", 1, "binsper10", 10}), -10.1), 1, "finite", "bins")', [-100:10:-10, -9:-2, -1:0.1:1], 1e-6)
