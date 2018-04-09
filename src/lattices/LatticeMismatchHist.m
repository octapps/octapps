## Copyright (C) 2014 Karl Wette
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
## @deftypefn {Function File} {@var{hgrm} =} LatticeMismatchHist ( @var{dim}, @var{lattice}, @var{opt}, @var{val}, @dots{} )
##
## Generates a normalised mismatch histogram for the given lattice
##
## @heading Arguments
##
## @table @var
## @item hgrm
## returned mismatch histogram
##
## @item dim
## number of @var{lattice} dimensions
##
## @item lattice
## @var{lattice} type; see e.g. @command{LatticeFindClosestPoint()}
##
## @end table
##
## @heading Options
##
## @table @code
## @item N
## number of points to use in generating histogram [default:1e6]
##
## @item dbin
## bin size of histogram [default: 0.01]
##
## @item mu_max
## use this maximum mismatch [default: 1.0]
##
## @item use_cache
## if true [default], use a cached version of the @var{lattice} mismatch
## histogram, if available. Note that the cached histogram will
## probably contain more points than requested in @var{N}.
##
## @end table
##
## @end deftypefn

function hgrm = LatticeMismatchHist( dim, lattice, varargin )

  ## check input
  assert( isscalar( dim ) && dim > 0 );
  assert( ischar( lattice ) );

  ## parse options
  parseOptions(varargin,
               {"N", "integer,strictpos,scalar", 1e6},
               {"dbin", "real,strictpos,scalar", 0.01},
               {"mu_max", "real,strictpos,scalar", 1.0},
               {"use_cache", "logical,scalar", true},
               []);

  ## if using cache
  if use_cache

    ## load mismatch histogram cache
    lattice_cache = load(__depends_extra_files__());

    ## check if mismatch histogram is in cache
    lattice_cache_field = sprintf("%s_lattice_mismatch_hgrms", lattice);
    if isfield(lattice_cache, lattice_cache_field)
      lattice_cache_hgrms = lattice_cache.(lattice_cache_field);
      if dim <= length(lattice_cache_hgrms)
        hgrm = lattice_cache_hgrms{dim};

        ## check that cached histogram has sufficient resolution
        if N <= histTotalCount(hgrm)

          ## rescale histogram to desired maximum mismatch
          hgrm = rescaleHistBins(hgrm, mu_max);

          ## resample histogram to desired bin size
          hgrm = resampleHist(hgrm, 1, unique([0.0:dbin:mu_max, mu_max]));

          ## return cached histogram
          return

        endif
      endif
    endif

  endif

  ## otherwise, create histogram for generating mismatch histogram
  hgrm = Hist(1, {"lin", "dbin", dbin});

  ## get the covering radius
  R = LatticeCoveringRadius( dim, lattice );

  ## generate N random points, at most 1e5 at a time
  while N > 0
    n = min(N, 1e5);
    N -= n;

    ## generate n random points within dim-D box [0, R]
    ## - size of box is important to get unbiased histograms
    x = R * randn( dim, n );

    ## find the nearest lattice point to each random point
    y = LatticeFindClosestPoint( x, lattice );

    ## work out mismatch
    mu = mu_max * sumsq(x - y, 1) ./ R.^2;

    ## add mismatches to histogram
    hgrm = addDataToHist(hgrm, mu(:));

  endwhile

endfunction

## This function is called by depends() to record extra file dependencies
function file = __depends_extra_files__()
  file = fullfile(fileparts(mfilename("fullpath")), "lattice_mismatch_hgrms.bin.gz");
endfunction

%!assert(meanOfHist(LatticeMismatchHist(1, "Zn")), 0.33333, 1e-2)
%!assert(meanOfHist(LatticeMismatchHist(2, "Zn")), 0.33333, 1e-2)
%!assert(meanOfHist(LatticeMismatchHist(3, "Zn")), 0.33333, 1e-2)
%!assert(meanOfHist(LatticeMismatchHist(4, "Zn")), 0.33333, 1e-2)
%!assert(meanOfHist(LatticeMismatchHist(5, "Zn")), 0.33333, 1e-2)
%!assert(meanOfHist(LatticeMismatchHist(1, "Ans")), meanOfHist(LatticeMismatchHist(1, "Zn")), 1e-2)
%!assert(meanOfHist(LatticeMismatchHist(2, "Ans")) > meanOfHist(LatticeMismatchHist(2, "Zn")))
%!assert(meanOfHist(LatticeMismatchHist(3, "Ans")) > meanOfHist(LatticeMismatchHist(3, "Zn")))
%!assert(meanOfHist(LatticeMismatchHist(4, "Ans")) > meanOfHist(LatticeMismatchHist(4, "Zn")))
%!assert(meanOfHist(LatticeMismatchHist(5, "Ans")) > meanOfHist(LatticeMismatchHist(5, "Zn")))
