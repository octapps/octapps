## Copyright (C) 2014 Reinhard Prix
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

## Usage: coef = LocalCostCoefficients ( cost_fun, Nseg, Tseg, mis=0.5, lattice="Zn" )
##
## Compute local power-law coefficients fit to given computing-cost function
## 'cost_fun' at StackSlide parameters 'Nseg' and 'Tseg = Tobs/Nseg', and
## (optionally) mismatch 'mis' and lattice type 'lattice'.
##
## The computing-cost function must be of the form 'cost_fun(Nseg, Tseg, mis)'
## and allow for vector inputs in all three input arguments.
##
## Return structure 'coef' has fields {delta, eta, kappa, nDim, cost }
## corresponding to the local power-law fit of computing cost
## cost = kappa *  mis^{-nDim/2} * Nseg^eta * Tseg^delta
## according to Eq.(61, 62,63, 64)
##
## [Equation numbers refer to Prix&Shaltev, PRD85, 084010 (2012)]
##

function coef = LocalCostCoefficients ( cost_fun, Nseg, Tseg, mis=0.5, lattice="Zn" )

  ## 'natural' spacings for computing the discrete derivatives: 5% variation around input point
  dTseg = 1e-4 * Tseg;
  dmis = 1e-4 * mis;
  dNseg   = 1e-4 * Nseg;
  ## Eq.(62a)
  Nseg_i = [ Nseg - dNseg, Nseg + dNseg];
  dlogCostN = diff ( log ( cost_fun ( Nseg_i, Tseg, mis, lattice ) ) );
  dlogN = diff ( log ( Nseg_i ) );
  coef.eta = dlogCostN / dlogN;

  ## Eq.(62b)
  Tseg_i = [ Tseg - dTseg, Tseg + dTseg ];
  dlogCostTseg = diff ( log ( cost_fun ( Nseg, Tseg_i, mis, lattice ) ) );
  dlogTseg = diff ( log ( Tseg_i ) );
  coef.delta = dlogCostTseg / dlogTseg;

  ## Eq.(64)
  mis_i  = [ mis - dmis, mis + dmis ];
  dlogCostMis = diff ( log ( cost_fun ( Nseg, Tseg, mis_i, lattice ) ) );
  dlogMis = diff ( log ( mis_i ) );
  coef.nDim = -2 * dlogCostMis / dlogMis;

  coef.cost = cost_fun ( Nseg, Tseg, mis, lattice );

  ## Eq.(63)
  coef.kappa = coef.cost / ( mis^(-0.5*coef.nDim) * Nseg^coef.eta * Tseg^coef.delta );

  return;

endfunction

%!test
%!  %% trivial test example first
%!  cost_fun = @(Nseg, Tseg, mis)  pi * mis.^(-3.3/2) .* Nseg.^2.2 .* Tseg.^4.4;
%!  coef = LocalCostCoefficients ( cost_fun, 100, 86400, 0.5 );
%!  assert ( coef.eta, 2.2, 2e-9 );
%!  assert ( coef.delta, 4.4, 2e-9 );
%!  assert ( coef.nDim, 3.3, 2e-9 );
%!  assert ( coef.kappa, pi, 2e-9 );
