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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{w} =} SensitivityScalingDeviationN ( @var{pFA}, @var{pFD}, @var{Nseg}, @var{approx} = "" )
##
## Compute the deviation parameter @var{w} of the local StackSlide-sensitivity power-law scaling
## coefficient from the weak-signal limit (where w=1).
## In the Gaussian weak-signal limit ("WSG"), the critical non-centrality RHO^2 scales exactly as
## RHO^2 ~ N^(1/2), and threshold signal-strength hth therefore scales as ~ N^(-1/4).
##
## In general the N-scaling deviates from this, and we can locally describe it as a power-law
## of the form RHO^2 ~ N^(1/(2w), and hth ~ N^(-1/(4w)), respectively, where @var{w} quantifies
## the devation from the WSG-scaling.
##
## @itemize
## @item @code{approx} == "":
## use full chi^2_(4*@var{Nseg}) distribution
## @item @code{approx} == "Gauss":
## use the Gaussian (N>>1) approximation
## @item @code{approx} == "WSG":
## return w=1 for the "weak-signal Gaussian" case
## @end itemize
##
## @var{Nseg} is allowed to be a vector, in which case the return w is also a vector.
##
## @end deftypefn

function w = SensitivityScalingDeviationN ( pFA, pFD, Nseg, approx = [] )

  if ( (length(pFA) != 1) || (length(pFD) != 1))
    error ("Sorry: can only deal with single input-values for 'pFA' and 'pFD'\n");
  endif

  ## ----- treat trivial 'WSG' case first
  w = ones ( size ( Nseg ) );
  if ( !isempty(approx) && (strcmpi ( approx, "WSG" ) == 1) )
    return;
  endif

  ## ----- Gaussian or NO approximations
  for i = 1:length(Nseg)
    Nseg_i = [ Nseg(i), Nseg(i) * ( 1 + 1e-4 ) ];
    dlogRho = diff ( log ( CriticalNoncentralityStackSlide ( pFA, pFD, Nseg_i, approx ) ) );
    dlogN = diff ( log ( Nseg_i ) );
    deriv = dlogRho / dlogN;

    w(i) = 1 / ( 2 * deriv);
  endfor

endfunction

%!test
%!  tol = -1e-6; pFD = 0.1;
%!  ## compare numbers to those from Prix&Shaltev,PRD85,084010(2012)
%!  wGauss1_10 = SensitivityScalingDeviationN ( 1e-10, pFD, 1, approx = "Gauss" );
%!  assert ( wGauss1_10, 1.38029957237533, tol );
%!  wGauss13_10 = SensitivityScalingDeviationN ( 1e-10, pFD, 13, approx = "Gauss" );
%!  assert ( wGauss13_10, 1.15371666877782, tol );
%!  w1_2 = SensitivityScalingDeviationN ( 1e-2, pFD, 1, approx = [] );
%!  assert ( w1_2, 1.88370817833829, tol );
%!  w13_2 = SensitivityScalingDeviationN ( 1e-2, pFD, 13, approx = [] );
%!  assert ( w13_2, 1.29212548567877, tol );
