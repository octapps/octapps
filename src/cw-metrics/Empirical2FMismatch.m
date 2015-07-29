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
  assert(all(0 <= mu_coh(:)));
  assert(all(0 <= mu_semi(:)));
  [err, mu_coh, mu_semi] = common_size(mu_coh, mu_semi);
  assert(err == 0, "'mu_coh' and 'mu_semi' are not of common size");

  ## coefficients of fit
  n = 1.0405;
  m = 0.0528;
  a = 0.4921;
  b = 0.6570;
  c = 0.4240;
  y = 0.8675;
  z = 1.0220;

  ## compute fit
  x = mu_semi + y .* mu_semi.*mu_coh + z .* mu_coh;
  mu_twoF = c .* x.^(0.5.*(m+n)) .* cosh(a.*log(x./b)).^(0.5.*(m-n)./a);

  ## sanity check
  assert(all(0 <= mu_twoF(:) & mu_twoF(:) <= 1));

endfunction


%!assert(Empirical2FMismatch(0, 0) == 0);
