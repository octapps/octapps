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
  n = 1.34626;
  a = [0.0932884, -0.708345, 1.7445, -0.374105];
  m = 0.8329;
  b = 0.85756;

  ## compute mean mismatch fit
  X1 = a(1).*msemi.^n + a(2).*msemi.^(0.75*n) + a(3).*msemi.^(0.5*n) + a(4).*msemi.^(0.25*n);
  X2 = b.*mcoh.^m;
  mtwoF = 2./pi .* atan(X1 + X2);
  mtwoF(mcoh == 0 & msemi == 0) = 0;
  mtwoF(mcoh == 0 & msemi == inf) = 1;
  mtwoF(mcoh == inf & msemi == 0) = 1;
  mtwoF(mcoh == inf & msemi == inf) = 1;
  assert(all(0 <= mtwoF(:) & mtwoF(:) <= 1));

  ## data for standard deviation mismatch fit
  u = [0.161937, 0.109856, 0.645859];
  q = [0.882317, 1.40982, 0.840252];
  v = [-0.431798, 0.369047, -0.0877485; 0.440843, 0, 0.695148; -1.1276, 3.34447, 1.78455];
  w = [0.0878029, 0.155218, 0.706146];

  ## compute standard deviation mismatch fit
  U1 = u(1) + v(1,1).*scoh.^q(1) + v(1,2).*scoh.^(2*q(1)) + v(1,3).*scoh.^(4*q(1));
  U2 = u(2) + v(2,1).*scoh.^q(2) + v(2,2).*scoh.^(2*q(2)) + v(2,3).*scoh.^(4*q(2));
  U3 = u(3) + v(3,1).*scoh.^q(3) + v(3,2).*scoh.^(2*q(3)) + v(3,3).*scoh.^(4*q(3));
  Y = max(0.1, log(U3.*ssemi).^2);
  Z = max(0.1, log(w(3).*scoh).^2);
  stwoF = abs(U1) .* exp(-abs(U2).*Y) + w(1) .* exp(-w(2).*Z);
  stwoF(scoh == 0 & ssemi == 0) = 0;
  stwoF(scoh == 0 & ssemi == inf) = 0;
  stwoF(scoh == inf & ssemi == 0) = 0;
  stwoF(scoh == inf & ssemi == inf) = 0;
  assert(all(0 <= stwoF(:)));

endfunction
