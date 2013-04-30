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

## Plot a histogram as a stair graph
## Syntax:
##   plotHist(hgrm, options, ...)
##   h = plotHist(...)
## where:
##   hgrm    = histogram class
##   options = options to pass to graphics function
##   h       = return graphics handle

function varargout = plotHist(hgrm, varargin)

  ## check input
  assert(isHist(hgrm));
  dim = histDim(hgrm);

  ## get histogram probability densities
  p = histProbs(hgrm);

  ## select plot based on dimension
  switch dim

    case 1

      ## if histogram is empty
      if sum(p(:)) == 0

        ## plot a stem point at zero
        h = plot([0, 0], [0, 1], varargin{:}, 0, 1, varargin{:});
        set(h(2), "color", get(h(1), "color"), "marker", "o");

      else

        ## get histogram bins
        [xl, xh] = histBins(hgrm, 1, "lower", "upper");

        ## find maximum range of non-zero probabilities
        ii = find(p > 0);
        ii = min(ii):max(ii);
        xl = reshape(xl(ii), 1, []);
        xh = reshape(xh(ii), 1, []);
        p = reshape(p(ii), 1, []);

        ## create staircase, with stems for infinite values
        x = reshape([xl(1), xh; xl, xh(end)], 1, []);
        y = reshape([0, p; p, 0], 1, []);
        if isinf(xl(1))
          x(x == -inf) = xl(2);
        endif
        if isinf(xh(end))
          x(x == +inf) = xh(end-1);
        endif

        ## plot staircase and possibly stems, delete lines which are not needed
        h = plot(x, y, varargin{:}, x(2), y(2), varargin{:}, x(end-1), y(end-1), varargin{:});
        if isinf(xl(1))
          set(h(2), "color", get(h(1), "color"), "marker", "o");
        else
          delete(h(2));
          h(2) = NaN;
        endif
        if isinf(xh(end))
          set(h(3), "color", get(h(1), "color"), "marker", "o");
        else
          delete(h(3));
          h(3) = NaN;
        endif
        h(isnan(h)) = [];

      endif

    case 2

      ## if histogram is empty
      if sum(p(:)) == 0

        ## plot a circular point at zero
        h = plot(0, 0, varargin{:});
        set(h, "marker", "o");

      else

        ## get histogram bins
        xc = histBinGrids(hgrm, 1, "centre");
        yc = histBinGrids(hgrm, 2, "centre");

        ## plot contours
        h = contour(xc, yc, p, varargin{:});

      endif

    otherwise
      error("%s: cannot plot %iD histograms", funcName, dim);

  endswitch

  ## return handles
  if nargout == 1
    varargout = {h};
  endif

endfunction
