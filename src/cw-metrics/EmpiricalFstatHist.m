## Copyright (C) 2015 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Compute an empirical F-statistic mismatch distribution histogram.
## Assumes a Gaussian distribution with mean and standard deviation
## given by EmpiricalFstatMismatch().
## Usage:
##   hgrm = EmpiricalFstatHist(dim, lattice, Tcoh, Tsemi, mcohmax, msemimax)
## where:
##   hgrm        = returned mismatch histogram
##   dim         = number of lattice dimensions
##   lattice     = lattice type; see e.g. LatticeFindClosestPoint()
##   Tcoh        = coherent segment time-span, in seconds
##   Tsemi       = semicoherent search time-span, in seconds
##   mcohmax     = maximum coherent metric mismatch
##   msemimax    = maximum semicoherent metric mismatch

function hgrm = EmpiricalFstatHist(dim, lattice, Tcoh, Tsemi, mcohmax, msemimax)

  ## check input
  assert(isscalar(dim) && dim > 0);
  assert(ischar(lattice));
  assert(isscalar(Tcoh) && Tcoh >= 0);
  assert(isscalar(Tsemi) && Tsemi >= 0);
  assert(isscalar(mcohmax) && mcohmax >= 0);
  assert(isscalar(msemimax) && msemimax >= 0);

  ## get the lattice histogram for the given dimensionality and type
  latt_hgrm = LatticeMismatchHist(dim, lattice);

  ## compute the mean and standard deviation of the coherent mismatch distribution
  mcoh = mcohmax * meanOfHist(latt_hgrm);
  scoh = mcohmax * stdvOfHist(latt_hgrm);

  ## compute the mean and standard deviation of the semicoherent mismatch distribution
  msemi = msemimax * meanOfHist(latt_hgrm);
  ssemi = msemimax * stdvOfHist(latt_hgrm);

  ## compute the mean and standard deviation of the F-statistic mismatch distribution
  [mean_twoF, stdv_twoF] = EmpiricalFstatMismatch(Tcoh, Tsemi, mcoh, msemi, scoh, ssemi);

  ## create a Gaussian histogram with the required mean and standard deviation
  hgrm = createGaussianHist(mean_twoF, stdv_twoF, "binsize", 0.01, "domain", [0, 1]);

endfunction
