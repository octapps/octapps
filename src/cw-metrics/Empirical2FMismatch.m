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

## Compute an empirical fit, derived from numerical simulations,
## to the average F-statistic mismatch as a function of the average
## coherent and semicoherent metric mismatches.
## Usage:
##   mu_twoF = Empirical2FMismatch(mu_coh, mu_semi)
## where
##   mu_twoF = average F-statistic mismatch
##   mu_coh  = average coherent metric mismatch
##   mu_semi = average semicoherent metric mismatch
## Both 'mu_coh' and 'mu_semi' may be vector inputs.
## Note that a non-interpolating search implies 'mu_coh = 0'.

function mu_twoF = Empirical2FMismatch(mu_coh, mu_semi)

  ## check input
  assert(all(mu_coh(:) >= 0));
  assert(all(mu_semi(:) >= 0));
  [err, mu_coh, mu_semi] = common_size(mu_coh, mu_semi);
  assert(err == 0, "'mu_coh' and 'mu_semi' are not of common size");

  ## coefficients of fit
  z = 0.629509858030036;
  n = -0.198439389875229;
  m = -0.115612865125759;
  a = 1.1723069920097;
  b = 1.31565865682617;
  c = 0.853959656503087;
  d = 1.02814193365039;

  ## compute fit
  x = mu_semi + c .* mu_semi.*mu_coh + d .* mu_coh;
  mu_twoF = 1 - z .* x.^n .* cosh(b + a.*log(x)).^m;

  ## fit breaks down for very small mismatches
  ii = (mu_coh < 0.05 & mu_semi < 0.05);
  mu_twoF(ii) = mu_coh(ii) + mu_semi(ii);

  ## sanity check
  assert(all(mu_twoF(:) >= 0));

endfunction


%!assert(Empirical2FMismatch(0, 0) == 0);
