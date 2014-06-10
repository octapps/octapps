## Copyright (C) 2011 Reinhard Prix
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

## Usage: w = SensivitiyScalingDeviationN ( pFA, pFD, Nseg, approx = "none" )
##
## Compute the deviation parameter 'w' of the local StackSlide-sensitivity power-law scaling
## coefficient from the weak-signal limit (where w=1).
## In the Gaussian weak-signal limit ("WSG"), the critical non-centrality RHO^2 scales exactly as
## RHO^2 ~ N^(1/2), and threshold signal-strength hth therefore scales as ~ N^(-1/4).
##
## In general the N-scaling deviates from this, and we can locally describe it as a power-law
## of the form RHO^2 ~ N^(1/(2w), and hth ~ N^(-1/(4w)), respectively, where 'w' quantifies
## the devation from the WSG-scaling.
##
## 'approx' == "none":  use full chi^2_(4*Nseg) distribution
## 'approx' == "Gauss": use the Gaussian (N>>1) approximation
## 'approx' == "WSG":   return w=1 for the "weak-signal Gaussian" case
##
## 'Nseg' is allowed to be a vector, in which case the return w is also a vector.

function w = SensitivityScalingDeviationN ( pFA, pFD, Nseg, approx = [] )

  if ( (length(pFA) != 1) || (length(pFD) != 1))
    error ("Sorry: can only deal with single input-values for 'pFA' and 'pFD'\n");
  endif

  ## ----- treat trivial 'WSG' case first
  if ( !isempty(approx) && (strcmpi ( approx, "WSG" ) == 1) )
    w = ones ( size ( Nseg ) );
    return;
  endif

  ## ----- Gaussian or NO approximations
  fun_rhoS2 = @(Nseg0) log( CriticalNoncentralityStackSlide ( pFA, pFD, Nseg0, approx ) );

  deriv = Nseg .* gradient ( fun_rhoS2, Nseg, 0.01 );

  w = 1 ./ ( 2 * deriv);

endfunction

%!test
%!  tol = 1e-6; pFD = 0.1;
%!  ## compare numbers to those from Prix&Shaltev,PRD85,084010(2012)
%!  wGauss1_10 = SensitivityScalingDeviationN ( 1e-10, pFD, 1, approx = "Gauss" );
%!  assert ( wGauss1_10, 1.380267280935366, tol );
%!  wGauss13_10 = SensitivityScalingDeviationN ( 1e-10, pFD, 13, approx = "Gauss" );
%!  assert ( wGauss13_10, 1.153719258981236, tol );
%!  w1_2 = SensitivityScalingDeviationN ( 1e-2, pFD, 1, approx = [] );
%!  assert ( w1_2, 1.883676083410966, tol );
%!  w13_2 = SensitivityScalingDeviationN ( 1e-2, pFD, 13, approx = [] );
%!  assert ( w13_2, 1.292132066561001, tol );
