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

## Generates a normalised mismatch histogram for the given lattice
## Usage:
##   hgrm = LatticeMismatchHist( dim, lattice, N, dbin )
## where:
##   hgrm    = returned mismatch histogram
##   dim     = number of lattice dimensions
##   lattice = lattice type; see e.g. LatticeFindClosestPoint()
##   N       = number of points to use in generating histogram
##   dbin    = bin size of histogram

function hgrm = LatticeMismatchHist( dim, lattice, N, dbin )

  ## check input
  assert( isscalar( dim ) && dim > 0 );
  assert( ischar( lattice ) );
  assert( isscalar( N ) && N > 0 );
  assert( isscalar( dbin ) && dbin > 0 );

  ## create histogram
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
    mu = sumsq(x - y, 1) ./ R.^2;

    ## add mismatches to histogram
    hgrm = addDataToHist(hgrm, mu(:));

  endwhile

endfunction
