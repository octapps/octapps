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

## Usage: [threshold, pFA_MPE, pFA_Lower, pFA_Upper] = estimateFAThreshold ( DATA, pFA, confidence=0.95 )
##
## Compute threshold for desired false-alarm probablity on samples DATA, returns the resulting maximum-posterior
## estimate pFA_MPE, and confidence interval [pFA_Lower, pFA_Upper]
##
## This is a simple helper function:
## estimate the 'rate' f of threshold-crossings from the samples DATA, namely via
## K = length( DATA > threshold ), N = length(DATA)
## The maximum-posteror estimate is fMPE=K/N,
## and the confidence interval [fLower, fUpper] is given by binomialConfidenceInterval(N,K,confidence)
##
## Note: the input pFA is allowed to be a vector, returns corresponding vectors
function [threshold, pFA_MPE, pFA_Lower, pFA_Upper] = estimateFAThreshold ( DATA, pFA, confidence=0.95 )

  assert ( isscalar ( confidence ) );

  threshold = empirical_inv ( 1 - pFA, DATA );

  ## prepare output quantities of same dimensions as 'pFA'
  pFA_MPE = pFA_Lower = pFA_Upper = NaN * ones ( size ( pFA ) );
  for i = 1:length( pFA(:) )
    ## now assess the actual pFA associated with that threshold on the given data
    [pFA_MPE(i), pFA_Lower(i), pFA_Upper(i)] = estimateRateFromSamples ( DATA, threshold(i), confidence );
  endfor

  return;

endfunction
