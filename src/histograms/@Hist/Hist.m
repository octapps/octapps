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

## Creates a new class representing a multi-dimensional histogram.
## Syntax:
##   hgrm = Hist(dim, type...)
## where:
##   hgrm = histogram class
##   dim  = dimensionality of the histogram
##   type = bin types, one per dimension

function hgrm = Hist(dim, varargin)

  ## check input
  assert(isscalar(dim));
  if length(varargin) != dim
    error("%s: number of bin types must match dimensionality", funcName);
  endif

  ## create class struct
  hgrm = struct;
  siz = ones(1, dim+1);
  for k = 1:dim

    ## parse bin type
    bintypek = varargin{k};
    if iscell(bintypek)
      if length(bintypek) == 0 || !ischar(bintypek{1})
        error("%s: bin type #i is not valid", funcName, k);
      endif
      hgrm.bintype{k} = struct("name", bintypek{1});

      ## select bin type
      switch hgrm.bintype{k}.name

        case "lin"   ## linear bin generator

          ## parse options
          parseOptions(bintypek(2:end),
                       {"dbin", "real,strictpos,scalar"},
                       {"bin0", "real,scalar", 0},
                       []);

          ## set bin type and create bins
          hgrm.bintype{k}.dbin = dbin;
          hgrm.bins{k} = [-inf, bin0, inf];

        case "log"   ## logarithmic bin generator

          ## parse options
          parseOptions(bintypek(2:end),
                       {"minrange", "real,strictpos,scalar"},
                       {"binsper10", "integer,strictpos,scalar"},
                       []);

          ## set bin type and create bins
          hgrm.bintype{k}.binsper10 = binsper10;
          hgrm.bins{k} = [-inf, linspace(-minrange, minrange, 2*binsper10 + 1), inf];          

        otherwise
          error("%s: unknown bin type '%s'", funcName, hgrm.bintype{k}.name)

      endswitch
    elseif isvector(bintypek)

      ## use given fixed bins
      hgrm.bintype{k} = struct("name", "fixed");
      hgrm.bins{k} = [-inf, reshape(sort(bintypek), 1, []), inf];

    endif

    ## size of count array in this dimension
    siz(k) = length(hgrm.bins{k}) - 1;

  endfor
  hgrm.counts = squeeze(zeros(siz));

  ## create class
  hgrm = class(hgrm, "Hist");

endfunction
