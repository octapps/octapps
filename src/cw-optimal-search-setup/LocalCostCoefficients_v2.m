## Copyright (C) 2014,2017 Reinhard Prix
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
## @deftypefn {Function File} { [ @var{coefCoh}, @var{coefInc} ] =} LocalCostCoefficients_v2 ( @var{cost_fun}, @var{Nseg}, @var{Tseg}, @var{mCoh}, @var{mInc} )
##
## Compute local power-law coefficients fit to given computing-cost function
## @var{cost_fun} at StackSlide parameters @var{Nseg} and @var{Tseg} = Tobs/@var{Nseg}, and
## mismatch parameters @var{mCoh} and @var{mInc}.
##
## The computing-cost struct @var{cost_fun} must be of the form
## @table @code
## @item lattice
## string defining template-bank lattice
## @item grid_interpolation
## boolean switch whether coherent grids are interpolated
## @item f
## cost function of the form '[costCoh, costInc] = f(@var{Nseg}, @var{Tseg}, @var{mCoh}, @var{mInc})'
## @end table
## and allow for vector inputs in all four input arguments.
##
## Return structures @var{coefCoh} and @var{coefInc} have fields @{delta, eta, kappa, nDim, cost @}
## corresponding to the local power-law fit of computing cost
## cost = kappa *  mis^@{-nDim/2@} * @var{Nseg}^eta * @var{Tseg}^delta
## according to Eq.(61, 62,63, 64)
##
## @heading Note
## Equation numbers refer to Prix&Shaltev, PRD85, 084010 (2012)
##
## @end deftypefn

function [ coefCoh, coefInc ] = LocalCostCoefficients_v2 ( costFuns, Nseg, Tseg, mCoh=0.5, mInc = 0.5 )

  assert ( isstruct ( costFuns ) && isfield ( costFuns, "lattice" ) && isfield ( costFuns, "f" ) && is_function_handle ( costFuns.f ) );
  assert ( isscalar(Nseg) && isscalar(Tseg) && isscalar(mCoh) && isscalar(mInc) );

  ## 'natural' spacings for computing the discrete derivatives: 1e-2 variation around input point
  dNseg = 1e-2 * Nseg;
  dTseg = 1e-2 * Tseg;
  dmCoh = 1e-2 * mCoh;
  dmInc = 1e-2 * mInc;

  Nseg_i = [ Nseg, Nseg-2*dNseg, Nseg-dNseg, Nseg+dNseg, Nseg+2*dNseg, Nseg*ones(1,4), Nseg*ones(1,4), Nseg*ones(1,4)];
  Tseg_i = [ Tseg, Tseg*ones(1,4), Tseg-2*dTseg, Tseg-dTseg, Tseg+dTseg, Tseg+2*dTseg, Tseg*ones(1,4), Tseg*ones(1,4)];
  mCoh_i = [ mCoh, mCoh*ones(1,4), mCoh*ones(1,4), mCoh-2*dmCoh, mCoh-dmCoh, mCoh+dmCoh, mCoh+2*dmCoh, mCoh*ones(1,4)];
  mInc_i = [ mInc, mInc*ones(1,4), mInc*ones(1,4), mInc*ones(1,4), mInc-2*dmInc, mInc-dmInc, mInc+dmInc, mInc+2*dmInc];

  [cc,  ci]  = costFuns.f ( Nseg_i, Tseg_i, mCoh_i, mInc_i );
  cc0 = cc(1);
  ci0 = ci(1);
  cN = [ [cc(2:3),  cc0, cc(4:5)]',   [ci(2:3),  ci0, ci(4:5)]'];
  cT = [ [cc(6:7),  cc0, cc(8:9)]',   [ci(6:7),  ci0, ci(8:9)]'];
  cM = [ [cc(10:11),cc0, cc(12:13)]', [ci(14:15),ci0, ci(16:17)]' ];

  dlogN = diff ( log ([ Nseg - 2 * dNseg, Nseg - dNseg, Nseg, Nseg + dNseg, Nseg + 2 * dNseg ] ));
  dlN = [ dlogN', dlogN' ];

  dlogT = diff ( log ([ Tseg - 2 * dTseg, Tseg - dTseg, Tseg, Tseg + dTseg, Tseg + 2 * dTseg ] ) );
  dlT = [ dlogT', dlogT' ];

  dlogmCoh = diff ( log ([ mCoh - 2 * dmCoh, mCoh - dmCoh, mCoh, mCoh + dmCoh, mCoh + 2 * dmCoh ] ) );
  dlogmInc = diff ( log ([ mInc - 2 * dmInc, mInc - dmInc, mInc, mInc + dmInc, mInc + 2 * dmInc ] ) );
  dlM = [ dlogmCoh', dlogmInc' ];

  ## Eq.(62a)
  dlogCostN = diff ( log ( cN ) );
  eta = sqrt ( mean ( ( dlogCostN ./ dlN ).^2 ) );
  coefCoh.eta = eta(1);
  coefInc.eta = eta(2);

  ## Eq.(62b)
  dlogCostTseg = diff ( log ( cT ) );
  delta = sqrt( mean ( ( dlogCostTseg ./ dlT ).^2 ) );
  coefCoh.delta = delta(1);
  coefInc.delta = delta(2);

  ## Eq.(64)
  dlogCostMis = diff ( log ( cM ) );
  nDim = sqrt( mean( ( -2 * dlogCostMis ./ dlM ).^2 ) );
  coefCoh.nDim = nDim(1);
  coefInc.nDim = nDim(2);

  coefCoh.cost = cc0;
  coefInc.cost = ci0;
  coefCoh.xi = meanOfHist ( LatticeMismatchHist ( round ( coefCoh.nDim ), costFuns.lattice ) );
  coefInc.xi = meanOfHist ( LatticeMismatchHist ( round ( coefInc.nDim ), costFuns.lattice ) );

  ## Eq.(63)
  coefCoh.kappa = coefCoh.cost / ( mCoh^(-0.5*coefCoh.nDim) * Nseg^coefCoh.eta * Tseg^coefCoh.delta );
  coefInc.kappa = coefInc.cost / ( mInc^(-0.5*coefInc.nDim) * Nseg^coefInc.eta * Tseg^coefInc.delta );

  ## check sanity of local cost coefficients:
  if ( coefCoh.eta <= 0 || coefCoh.delta <= 0 || coefCoh.nDim <= 0 || coefCoh.kappa <= 0 )
    error ( "LocalCostCoefficient_v2(): invalid local costCoh ~ %g * Nseg^%g * Tseg^%g * mc^(-%g/2) at at Nseg=%f, Tseg=%f, mis=%f", coefCoh.kappa, coefCoh.eta, coefCoh.delta, coefCoh.nDim, Nseg, Tseg, mis );
  endif
  if ( coefInc.eta <= 0 || coefInc.delta <= 0 || coefInc.nDim <= 0 || coefInc.kappa <= 0 )
    error ( "LocalCostCoefficient_v2(): invalid local costInc ~ %g * Nseg^%g * Tseg^%g * mc^(-%g/2) at at Nseg=%f, Tseg=%f, mis=%f", coefInc.kappa, coefInc.eta, coefInc.delta, coefInc.nDim, Nseg, Tseg, mis );
  endif

  coefCoh.lattice = costFuns.lattice;
  coefInc.lattice = costFuns.lattice;

  return;

endfunction
%!function [costCoh, costInc] = test_f (Nseg, Tseg, mCoh, mInc)
%!  costCoh = pi * mCoh.^(-3.3/2) .* Nseg.^2.2 .* Tseg.^4.4;
%!  costInc = pi * mInc.^(-1.3/2) .* Nseg.^4.2 .* Tseg.^1.4;
%!  return;
%!endfunction
%!
%!test
%!  ## trivial test example first
%! tol = 1e-8;
%! testCostFunction = struct ( "lattice", "Ans", "f", @test_f );
%!  [coefCoh, coefInc] = LocalCostCoefficients_v2 ( testCostFunction, 100, 86400, 0.5, 0.3 );
%!  assert ( coefCoh.eta, 2.2, tol);
%!  assert ( coefCoh.delta, 4.4, tol );
%!  assert ( coefCoh.nDim, 3.3, tol );
%!  assert ( coefCoh.kappa, pi, tol );
%!  assert ( coefCoh.lattice, "Ans");
%!
%!  assert ( coefInc.eta, 4.2, tol);
%!  assert ( coefInc.delta, 1.4, tol );
%!  assert ( coefInc.nDim, 1.3, tol );
%!  assert ( coefInc.kappa, pi, tol );
%!  assert ( coefInc.lattice, "Ans");
