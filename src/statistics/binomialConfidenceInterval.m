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

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{fLower}, @var{fUpper} ] =} binomialConfidenceInterval ( @var{N}, @var{K}, @var{confidence} )
##
## Compute the posterior @var{confidence} interval [@var{fLower}, @var{fUpper}] for the true rate f
## given a drawing experiment with @var{K} "successful" results out of @var{N} trials.
## The @var{confidence} interval satisfies
## confidence = int_@{fLower@}^@{fUpper@} pdf(f|@var{N},@var{K}) df,
## where pdf(f|@var{N},@var{K}) is the posterior pdf for the rate f, which
## is computed using the function binomialRatePDF(f,@var{N},@var{K}).
##
## The @var{confidence}-interval is constructed with iso-probability endpoints
## (if possible), namely
## P(@var{fLower}) = P(@var{fUpper}), which is guaranteed to bracket the maximum of the pdf.
## In the special cases where @var{K} = 0 or @var{K} = @var{N}, we return the "single-sided" intervals
## [0,@var{fUpper}] or [@var{fLower},1], respectively.
##
## @heading Note
##
## all inputs must be scalars! @var{confidence} must be in (0,1)
##
## @end deftypefn

function [fLower, fUpper] = binomialConfidenceInterval ( N, K, confidence )

  ## check input santity
  assert ( isscalar ( N ) && isscalar ( K ) && isscalar ( confidence ) );
  assert ( N > 0 && (N == round(N)) );
  assert ( K >= 0 && K <= N && K == round(K));
  assert ( (confidence > 0) && (confidence < 1) );

  Nd = 1000;    ## discretation of numerical integrals

  fMPE = K ./ N;
  fE = (K+1)/(N+2);
  sigf = sqrt ( fE * ( 1 - fE ) / (N+3) );

  ## use a '+-5-sigma interval around fMPE as the working domain'
  fMin = max(0, fMPE - 5 * sigf );
  fMax = min(1, fMPE + 5 * sigf );
  df = (fMax-fMin)/Nd;
  f = linspace ( fMin, fMax, Nd + 1);   ## Nd intervals, Nd+1 points
  Pd   = df * binomialRatePDF ( f, N, K );      ## discretized probability 'histogram'
  PMax = df * binomialRatePDF ( fMPE, N, K );

  [PIso0, delta, INFO, OUTPUT] = fzero ( @(PIso)  sum ( Pd ( find ( Pd >= PIso ) ) ) - confidence, [0, PMax] );
  assert ( INFO == 1 );

  inds0 = find ( Pd >= PIso0 );
  ## paranoia sanity check on final confidence
  conf0 = sum ( Pd(inds0) );
  relerr = abs( conf0 - confidence ) / confidence;
  assert ( relerr < 0.01 );     ## tolerate 1% error on resulting confidence

  fLower = f ( min(inds0) );
  fUpper = f ( max(inds0) );

  return;

endfunction

## ---------- testing and demo functions ----------
%!test
%!  binomialConfidenceInterval(10, 0, 0.9545);
%!demo if 1
%!  function plot_this ( N, K )
%!    conf2sigma = 0.9545;
%!    [fLower, fUpper] = binomialConfidenceInterval ( N, K, conf2sigma );
%!    fMPE = K / N;
%!    fE = (K+1)/(N+2);
%!    sigf = sqrt ( fE * ( 1 - fE ) / (N+3) );
%!    fMin = max(0, fMPE - 3.5 * sigf );
%!    fMax = min(1, fMPE + 3.5 * sigf );
%!    fLowerGauss = fE - 2*sigf;
%!    fUpperGauss = fE + 2*sigf;
%!    fi = linspace ( fMin, fMax, 100);
%!    pdf_f = binomialRatePDF ( fi, N, K );
%!    PMax = max ( pdf_f );
%!    ylim([0,1.05 * PMax]);
%!    set ( 0, "defaultlinemarkersize", 10 );
%!    plot ( fi, pdf_f, fMPE, PMax, "rx", [fLower, fUpper], [PMax,PMax], "r+-",
%!          fLower*[1,1], ylim(), "color", "black", "linestyle", "--", fUpper*[1,1], ylim(), "color", "black", "linestyle", "--",
%!          fMPE*[1,1], ylim(), "color", "black", "linestyle", ":",
%!          [fLowerGauss, fUpperGauss], 1.02*[PMax,PMax], "m+-"
%!          );
%!    xlabel("f"); ylabel("pdf(f|N,K)");
%!    tstr = sprintf ("N=%d, K=%d, confidence=%.2f%%", N, K, conf2sigma * 100.0 );
%!    title ( tstr );
%!  endfunction
%!  figure(1); clf;
%!  subplot(2,3,1); plot_this ( 10, 0 );
%!  subplot(2,3,2); plot_this ( 10, 1 );
%!  subplot(2,3,3); plot_this ( 500, 300 );
%!  subplot(2,3,4); plot_this ( 5000, 4999 );
%!  subplot(2,3,5); plot_this ( 50000, 25000 );
%!  subplot(2,3,6); plot_this ( 50000, 10000 );
%!  ## red shows the exact posterior 95.45% confidence intervals
%!  ## magenta shows the Gaussian +-2sigma intervals centered on the expectation value of f
%!  endif
