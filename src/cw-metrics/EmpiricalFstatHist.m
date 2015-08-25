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
##   hgrm = EmpiricalFstatHist(dim, lattice, mu_max_coh, mu_max_semi)
## where:
##   hgrm        = returned mismatch histogram
##   dim         = number of lattice dimensions
##   lattice     = lattice type; see e.g. LatticeFindClosestPoint()
##   mu_max_coh  = maximum coherent mismatch
##   mu_max_semi = maximum semicoherent mismatch

function hgrm = EmpiricalFstatHist(dim, lattice, mu_max_coh, mu_max_semi)

  ## check input
  assert(isscalar(dim) && dim > 0);
  assert(ischar(lattice));
  assert(isscalar(mu_max_coh) && mu_max_coh >= 0);
  assert(isscalar(mu_max_semi) && mu_max_semi >= 0);

  ## get the lattice histogram for the given dimensionality and type
  latt_hgrm = LatticeMismatchHist(dim, lattice);

  ## compute the mean and standard deviation of the coherent mismatch distribution
  mean_mu_coh = mu_max_coh * meanOfHist(latt_hgrm);
  stdv_mu_coh = mu_max_coh * stdvOfHist(latt_hgrm);

  ## compute the mean and standard deviation of the semicoherent mismatch distribution
  mean_mu_semi = mu_max_semi * meanOfHist(latt_hgrm);
  stdv_mu_semi = mu_max_semi * stdvOfHist(latt_hgrm);

  ## compute the mean and standard deviation of the F-statistic mismatch distribution
  [mean_twoF, stdv_twoF] = EmpiricalFstatMismatch(mean_mu_coh, mean_mu_semi, stdv_mu_coh, stdv_mu_semi);

  ## create a Gaussian histogram with the required mean and standard deviation
  hgrm = createGaussianHist(mean_twoF, stdv_twoF, "binsize", 0.01, "domain", [0, 1]);

endfunction
