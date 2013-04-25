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

## Return quantities relating to the histogram bin boundaries.
## Syntax:
##   [binq, ...] = histBins(hgrm, k, "type", ...)
## where:
##   hgrm = histogram class
##   k    = dimension along which to return bin quantities
##   type = one of:
##            "lower": lower bin boundary
##            "upper": upper bin boundary
##            "centre": bin centre
##            "width": bin width
##   binq = bin quantities

function varargout = histBins(hgrm, k, varargin)

  ## check input
  assert(isHist(hgrm));
  assert(1 <= k && k <= length(hgrm.bins));

  ## loop over requested output
  for i = 1:length(varargin)

    ## what do you want?
    fbins = hgrm.bins{k}(2:end-1);
    switch varargin{i}
      case "lower"
        binq = [-inf, fbins(1:end-1), inf];
      case "centre"
        binq = [-inf, (fbins(1:end-1) + fbins(2:end)) / 2, inf];
      case "upper"
        binq = [-inf, fbins(2:end), inf];
      case "width"
        binq = [0, diff(fbins), 0];
      otherwise
        error("Invalid bin quantity '%s'!", varargin{i});
    endswitch

    ## return binq
    varargout{i} = binq(:);

  endfor

endfunction
