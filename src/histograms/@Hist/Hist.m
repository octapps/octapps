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
## @deftypefn {Function File} {@var{hgrm} =} Hist ( @var{dim}, @var{type}@dots{} )
##
## Create a new object representing a multi-dimensional histogram.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item dim
## dimensionality of the histogram
##
## @item type
## bin types, one per dimension; possible types:
## @itemize
## @item
## @{@code{lin}, @code{dbin}, @samp{bin width}, @dots{},
## @code{bin0}, @samp{starting bin (default 0)}@}
##
## @item
## @{@code{log}, @code{minrange}, @samp{starting minimal bin range (default: auto)}, @dots{},
## @code{binsper10}, @samp{number of bins to add per decade}@}
##
## @item
## [@samp{bin}, @samp{bin}, @dots{}]
##
## Fixed array of bins, cannot be extended
##
## @end itemize
##
## @end table
##
## @end deftypefn

function hgrm = Hist(dim, varargin)

  ## default options for no-argument constructor, which is called by load()
  ## when Hist() classes are saved to files, and so must work correctly
  if nargin == 0
    dim = 1;
    varargin = {[0]};
  endif

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
                       {"minrange", "real,strictpos,scalar", []},
                       {"binsper10", "integer,strictpos,scalar"},
                       []);

          ## set bin type and create bins
          hgrm.bintype{k}.binsper10 = binsper10;
          if isempty(minrange)
            hgrm.bins{k} = [-inf, 0, inf];
          else
            hgrm.bins{k} = [-inf, linspace(-minrange, minrange, 2*binsper10 + 1), inf];
          endif

        otherwise
          error("%s: unknown bin type '%s'", funcName, hgrm.bintype{k}.name)

      endswitch
    elseif isvector(bintypek)

      ## use given fixed bins
      hgrm.bintype{k} = struct("name", "fixed");
      hgrm.bins{k} = [-inf, reshape(sort(bintypek), 1, []), inf];

    else
      error("%s: unknown bin type #%i", funcName, k)

    endif

    ## size of count array in this dimension
    siz(k) = length(hgrm.bins{k}) - 1;

  endfor
  hgrm.counts = squeeze(zeros(siz));

  ## create class
  hgrm = class(hgrm, "Hist");

endfunction

%!assert(class(Hist()), "Hist")
%!assert(class(Hist(1, {"lin", "dbin", 0.1})), "Hist")
%!assert(class(Hist(2, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1})), "Hist")
%!assert(class(Hist(3, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1})), "Hist")
%!assert(class(Hist(4, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1})), "Hist")
%!assert(class(Hist(5, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1}, {"lin", "dbin", 0.1})), "Hist")
