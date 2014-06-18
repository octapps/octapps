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

## Adds the given input data to the histogram.
## If the histogram is too small, more bins are added.
## Syntax:
##   hgrm = addDataToHist(hgrm, data)
## where:
##   hgrm = histogram class
##   data = input histogram data

function hgrm = addDataToHist(hgrm, data)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);
  assert(ismatrix(data) && size(data, 2) == dim);

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
    if any(finii) && (datamin < binmin || datamax > binmax)
      newbinslo = [];
      newbinshi = [];

      ## select bin type
      switch hgrm.bintype{k}.name

        case "fixed"   ## fixed bins, cannot be extended
          error("%s: data range [%g,%g] extends beyond range of fixed bins [%g,%g]", funcName, datamin, datamax, binmin, binmax);

        case "lin"   ## linear bin generator
          dbin = hgrm.bintype{k}.dbin;

          ## create new lower bins, if needed
          if datamin < binmin
            newbinslo = binmin - (ceil((binmin - datamin) / dbin):-1:1) * dbin;
          endif

          ## create new upper bins, if needed
          if datamax > binmax
            newbinshi = binmax + (1:ceil((datamax - binmax) / dbin)) * dbin;
          endif

        case "log"   ## logarithmic bin generator
          binsper10 = hgrm.bintype{k}.binsper10;

          ## if no minimum bin range has been created
          if length(bins) == 1

            ## use range of data + 5% to prevent data being added to Inf bins
            range = max(abs(datamin), abs(datamax)) * 1.01;

            ## create minimum bins
            newbins = linspace(0, range, binsper10);
            newbinslo = -newbins(end:-1:2);
            newbinshi = +newbins(2:end);

          else

            ## extend lower bins, if needed
            range = newbinmin = binmin;
            do
              range *= 10;
              binslo = linspace(range, newbinmin, binsper10);
              newbinslo = [binslo(1:end-1), newbinslo];
              newbinmin = newbinslo(1);
            until !(datamin < newbinmin)

            ## extend upper bins, if needed
            range = newbinmax = binmax;
            do
              range *= 10;
              binshi = linspace(newbinmax, range, binsper10);
              newbinshi = [newbinshi, binshi(2:end)];
              newbinmax = newbinshi(end);
            until !(datamax > newbinmax)

          endif

        otherwise
          error("%s: unknown bin type '%s'", funcName, hgrm.bintype{k}.name)

      endswitch

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
