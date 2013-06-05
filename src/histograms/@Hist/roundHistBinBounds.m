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

## Round given histogram bins boundaries to within a small
## fraction of the smallest overall bin size, so that one
## can compare floating-point precision bin boundaries robustly.
## Syntax:
##   [bins, bins, ...] = roundHistBinBounds(bins, bins, ...)
## where:
##   bins = bin boundaries

function varargout = roundHistBinBounds(varargin)

  assert(nargin == nargout);

  if all(cellfun(@(x) length(x) == 1, varargin))

    [varargout{1:nargout}] = deal(mean(cell2mat(varargin)));

  else

    dbins = inf;
    for i = 1:length(varargin)
      dbins = min([dbins, diff(varargin{i})]);
    endfor
    dbins = 10^(floor(log10(dbins)) - 3);
    for i = 1:length(varargin)
      varargout{i} = round(varargin{i} / dbins) * dbins;
    endfor

  endif

endfunction
