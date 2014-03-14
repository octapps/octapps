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

## Usage: [fMPE, fE, fLower, fUpper] = estimateRateFromSamples ( DATA, threshold, confidence )
##
## Compute maximum-posterior rate estimate fMPE and confidence-interval [fLower, fUpper].
##
## This is a simple helper function:
## estimate the 'rate' f of threshold-crossings from the samples DATA, namely via
## K = length( DATA > threshold ), N = length(DATA)
## The maximum-posteror estimate is fMPE=K/N,
## and the confidence interval [fLower, fUpper] is given by binomialConfidenceInterval(N,K,confidence)
##
## Note: threshold is allowed to be a vector, returns corresponding rate vectors
function [fMPE, fLower, fUpper] = estimateRateFromSamples ( DATA, threshold, confidence=0.95 )

  assert ( isscalar(confidence) );

  assert ( isscalar(threshold) );


  K = length ( find ( DATA > threshold ) );
  N = length ( DATA );

  fMPE = K / N;
  [fLower, fUpper] = binomialConfidenceInterval ( N, K, confidence );
  return;
endfunction
