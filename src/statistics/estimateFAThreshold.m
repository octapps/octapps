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
## @deftypefn {Function File} { [ @var{threshold}, @var{pFA_MPE}, @var{pFA_Lower}, @var{pFA_Upper}, @var{threshold_Lower}, @var{threshold_Upper} ] =} estimateFAThreshold ( @var{DATA}, @var{pFA}, @var{confidence=0.95} )
##
## Compute @var{threshold} for desired false-alarm probablity on samples @var{DATA}, returns the resulting maximum-posterior
## estimate @var{pFA_MPE}, and @var{confidence} interval [@var{pFA_Lower}, @var{pFA_Upper}].
## Also returns the corresponding @var{confidence} interval in thresholds [@var{threshold}_Lower, @var{threshold}_Upper],
## obtained by simply re-computing @var{threshold} on [@var{pFA_Lower}, @var{pFA_Upper}].
##
## @heading Note
##
## the input @var{pFA} is allowed to be a vector, returns corresponding vectors
##
## @end deftypefn

function [threshold, pFA_MPE, pFA_Lower, pFA_Upper, threshold_Lower, threshold_Upper] = estimateFAThreshold ( DATA, pFA, confidence=0.95 )

  assert ( isscalar ( confidence ) );

  threshold = empirical_inv ( 1 - pFA, DATA );

  ## now assess the actual pFA associated with that threshold on the given data
  [pFA_MPE, pFA_Lower, pFA_Upper] = estimateRateFromSamples ( DATA, threshold, confidence );

  ## estimate uncertainty on threshold by going back to threshold(pFA)
  threshold_Upper = empirical_inv ( 1 - pFA_Lower, DATA );
  threshold_Lower = empirical_inv ( 1 - pFA_Upper, DATA );

  return;

endfunction

%!assert(estimateFAThreshold(0:1000, 0.1), 900)
%!assert(estimateFAThreshold(0:1000, 0.5), 500)
%!assert(estimateFAThreshold(0:1000, 0.9), 100)
