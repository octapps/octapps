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

## Usage: coef = LocalCostCoefficients ( cost_fun, Nseg, Tseg, mis=0.5 )
##
## Compute local power-law coefficients fit to given computing-cost function
## 'cost_fun' at StackSlide parameters 'Nseg' and 'Tseg = Tobs/Nseg', and
## (optionally) mismatch 'mis'.
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

function coef = LocalCostCoefficients ( cost_fun, Nseg, Tseg, mis=0.5 )

  ## 'natural' spacings for computing the discrete derivatives: 1e-2 variation around input point
  dTseg = 1e-2 * Tseg;
  dmis  = 1e-2 * mis;
  dNseg = 1e-2 * Nseg;

  ## Eq.(62a)
  Nseg_i = [ Nseg - 2 * dNseg, Nseg - dNseg, Nseg, Nseg + dNseg, Nseg + 2 * dNseg ];
  dlogCostN = diff ( log ( cost_fun ( Nseg_i, Tseg, mis ) ) );
  dlogN = diff ( log ( Nseg_i ) );
  coef.eta = sqrt ( mean ( ( dlogCostN ./ dlogN ).^2 ) );

  ## Eq.(62b)
  Tseg_i = [ Tseg - 2 * dTseg, Tseg - dTseg, Tseg, Tseg + dTseg, Tseg + 2 * dTseg ];
  dlogCostTseg = diff ( log ( cost_fun ( Nseg, Tseg_i, mis ) ) );
  dlogTseg = diff ( log ( Tseg_i ) );
  coef.delta = sqrt( mean ( ( dlogCostTseg ./ dlogTseg ).^2 ) );

  ## Eq.(64)
  mis_i  = [ mis - 2 * dmis, mis - dmis, mis, mis + dmis, mis + 2 * dmis ];
  dlogCostMis = diff ( log ( cost_fun ( Nseg, Tseg, mis_i ) ) );
  dlogMis = diff ( log ( mis_i ) );
  coef.nDim = sqrt( mean( ( -2 * dlogCostMis ./ dlogMis ).^2 ) );

  [coef.cost, ~, coef.lattice ] = cost_fun ( Nseg, Tseg, mis );
  coef.xi = meanOfHist ( LatticeMismatchHist ( round ( coef.nDim ), coef.lattice ) );

  ## Eq.(63)
  coef.kappa = coef.cost / ( mis^(-0.5*coef.nDim) * Nseg^coef.eta * Tseg^coef.delta );

  ## check sanity of local cost coefficients:
  if ( coef.eta <= 0 || coef.delta <= 0 || coef.nDim <= 0 || coef.kappa <= 0 )
    error ( "LocalCostCoefficient(): got invalid local cost ~ %g * Nseg^%g * Tseg^%g * mc^(-%g/2) at at Nseg=%f, Tseg=%f, mis=%f", coef.kappa, coef.eta, coef.delta, coef.nDim, Nseg, Tseg, mis );
  endif

  return;

endfunction

%!function [cost, Nt, lattice] = testCostFunction (Nseg, Tseg, mis)
%!  cost = pi * mis.^(-3.3/2) .* Nseg.^2.2 .* Tseg.^4.4;
%!  Nt = NA;
%!  lattice = "Ans";
%!  return;
%!endfunction
%!
%!test
%!  %% trivial test example first
%! tol = 1e-8;
%!  coef = LocalCostCoefficients ( @testCostFunction, 100, 86400, 0.5 );
%!  assert ( coef.eta, 2.2, tol);
%!  assert ( coef.delta, 4.4, tol );
%!  assert ( coef.nDim, 3.3, tol );
%!  assert ( coef.kappa, pi, tol );
%!  assert ( coef.lattice, "Ans");
