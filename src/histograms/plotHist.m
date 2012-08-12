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
##   plotHist(hgrm, hgrmopt, options, ...)
##   h = plotHist(...)
## where:
##   hgrm    = histogram struct
##   hgrmopt = optional histogram options:
##             "nonorm" = do not normalise histogram
##   options = options to pass to graphics function
##   h       = return graphics handle

function varargout = plotHist(hgrm, varargin)

  ## check input
  assert(isHist(hgrm));
  
  ## check histogram is 1D
  if (length(hgrm.xb) > 1)
    error("%s: can only plot 1D histogram", funcName);
  endif

  ## normalise histogram
  if strcmp(varargin{1}, "nonorm")
    varargin = varargin(2:end);
  else
    hgrm = normaliseHist(hgrm);
  endif

  ## get finite bins and probabilities
  [xb, px] = finiteHist(hgrm);
  xb = xb{1};

  ## if histogram is singular
  if isempty(px)

    ## plot a stem
    h = stem(xb, 1.0, varargin{:});

  else

    ## otherwise plot stairs
    ii = find(px > 0);
    ii = min(ii):max(ii);
    x = [xb(ii(1)); xb(ii)(:); xb(ii(end))];
    y = [0; px(ii)(:); 0];
    h = stairs(x, y, varargin{:});

  endif

  ## return handles
  if nargout == 1
    varargout = {h};
  endif

endfunction
