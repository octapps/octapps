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
## to the F-statistic mismatch as a function of the coherent and
## semicoherent metric mismatches.
## Usage:
##   mtwoF          = EmpiricalFstatMismatch(mcoh, msemi)
##   [mtwoF, stwoF] = EmpiricalFstatMismatch(mcoh, msemi, scoh, ssemi)
## where
##   mtwoF          = mean F-statistic mismatch
##   mcoh           = mean coherent metric mismatch
##   msemi          = mean semicoherent metric mismatch
##   stwoF          = standard deviation of F-statistic mismatch
##   scoh           = standard deviation of coherent metric mismatch
##   ssemi          = standard deviation of semicoherent metric mismatch
## Input variables may also be vectors.
## Note that a non-interpolating search implies 'mcoh = 0'.

function [mtwoF, stwoF] = EmpiricalFstatMismatch(mcoh, msemi, scoh=0, ssemi=0)

  ## check input
  assert(all(0 <= mcoh(:)));
  assert(all(0 <= msemi(:)));
  assert(all(0 <= scoh(:)));
  assert(all(0 <= ssemi(:)));
  [err, mcoh, msemi, scoh, ssemi] = common_size(mcoh, msemi, scoh, ssemi);
  assert(err == 0, "Input variables are not of common size");

  ## data for mean mismatch fit
  n = 1.479;
  a = [0.0763369, -0.613027, 1.52882, -0.234391];
  m = 0.850449;
  b = 0.859776;

  ## compute mean mismatch fit
  X = a(1).*msemi.^n + a(2).*msemi.^(0.75*n) + a(3).*msemi.^(0.5*n) + a(4).*msemi.^(0.25*n);
  Y = b.*mcoh.^m;
  mtwoF = 2./pi .* atan(X + Y);
  mtwoF(mcoh == 0 & msemi == 0) = 0;
  mtwoF(mcoh == 0 & msemi == inf) = 1;
  mtwoF(mcoh == inf & msemi == 0) = 1;
  mtwoF(mcoh == inf & msemi == inf) = 1;
  mtwoF(mtwoF < 0) = 0;
  mtwoF(mtwoF > 1) = 1;

  ## data for standard deviation mismatch fit
  u = [0.133781, 0.124426, 0.888016];
  q = 0.918109;
  v = [3.08587, 2.21999, 0.896751];
  w = [0.0495105, 0.206969, 1.10315];

  ## compute standard deviation mismatch fit
  X = u(1) .* exp(-u(2) .* log(u(3).*ssemi).^2);
  Y = v(1).*scoh.^q + v(2).*scoh.^(2*q) + v(3).*scoh.^(4*q);
  Z = w(1) .* exp(-w(2) .* log(w(3).*scoh).^2);
  stwoF = X .* exp(-Y) + Z;
  stwoF(scoh == 0 & ssemi == 0) = 0;
  stwoF(scoh == 0 & ssemi == inf) = 0;
  stwoF(scoh == inf & ssemi == 0) = 0;
  stwoF(scoh == inf & ssemi == inf) = 0;
  stwoF(stwoF < 0) = 0;

endfunction
