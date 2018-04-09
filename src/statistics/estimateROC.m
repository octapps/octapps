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
## @deftypefn {Function File} { [ @var{pDet_MPE}, @var{pDet_Lower}, @var{pDet_Upper}, @var{pFA_MPE}, @var{pFA_Lower}, @var{pFA_Upper} ] =} estimateROC ( @var{DATA_noise}, @var{DATA_signal}, @var{pFA}, @var{confidence} = 0.95 )
##
## Compute the Receiver Operator Characteristic (ROC) function pDet(@var{pFA}) on given samples drawn under
## the noise hypothesis, @var{DATA_noise}, and under the signal hypothesis, @var{DATA_signal}.
## Returns estimates for the detection-probability and false-alarm probability for the given DATA samples and
## a vector of desired false-alarm probabilities @var{pFA}.
##
## @heading Note
##
## this function replaces the deprecated @command{estimateFalseDismissal()}
##
## @end deftypefn

function [pDet_MPE, pDet_Lower, pDet_Upper, pFA_MPE, pFA_Lower, pFA_Upper] = estimateROC ( DATA_noise, DATA_signal, pFA, confidence=0.95 )

  assert ( isscalar ( confidence ) );

  [threshold, pFA_MPE, pFA_Lower, pFA_Upper] = estimateFAThreshold ( DATA_noise, pFA, confidence );

  [pDet_MPE, pDet_Lower, pDet_Upper] = estimateRateFromSamples ( DATA_signal, threshold, confidence );

  return;

endfunction

%!test
%!  Ntrials_N = 600; Ntrials_S = 300;
%!  stat_S = normrnd ( 1, 1, 1, Ntrials_S );
%!  stat_N = normrnd ( 0, 1, 1, Ntrials_N );
%!  pFA = linspace ( 0, 1, 15 );
%!  [pDet_MPE, pDet_Lower, pDet_Upper, pFA_MPE, pFA_Lower, pFA_Upper] = estimateROC ( stat_N, stat_S, pFA, confidence=0.9545 );
%!demo
%!  Ntrials_N = 600; Ntrials_S = 300;
%!  stat_S = normrnd ( 1, 1, 1, Ntrials_S );
%!  stat_N = normrnd ( 0, 1, 1, Ntrials_N );
%!  pFA = linspace ( 0, 1, 15 );
%!  [pFD0, dpDet0] = estimateFalseDismissal ( pFA, stat_N, stat_S );
%!  [pDet_MPE, pDet_Lower, pDet_Upper, pFA_MPE, pFA_Lower, pFA_Upper] = estimateROC ( stat_N, stat_S, pFA, confidence=0.9545 );
%!  figure(1);
%!  set ( 0, "defaultlinemarkersize", 5 );
%!  set ( 0, "defaultaxesfontsize", 15 );
%!  clf; hold on;
%!  hax = errorbar ( pFA, 1 - pFD0, 2*dpDet0, "~x;estimateFalseDismissal();",
%!                   pFA_MPE, pDet_MPE, (pFA_MPE - pFA_Lower), (pFA_Upper-pFA_MPE), (pDet_MPE - pDet_Lower), (pDet_Upper-pDet_MPE), "#~>or;estimateROC();" );
%!  line ( [0, 1, 1, 0, 0 ], [ 0, 0, 1, 1, 0 ], "linestyle", ":" );
%!  hold off;
%!  set ( hax, "markersize", 10 );
%!  xlim([-0.05, 1.05]); ylim([-0.1, 1.15]);
%!  legend ("location", "northwest" ); legend("boxoff");
%!  xlabel("pFA"); ylabel("pDet");
