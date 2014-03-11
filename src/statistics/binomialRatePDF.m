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

## Usage: pdf = binomialRatePDF ( f, N, K )
##
## Return the posterior pdf(f|N,K) for the true 'rate' f given a drawing
## experiment with K "successful" results out of N trials, assuming a
## uniform prior on f in [0,1], which yields
## pdf(f|N,K) = (N+1)!/(K! (N-K)!) * f^K * (1-f)^(N-K)
## This expression would be numerically overflowing very
## easily when N,K>>1, and so we use the fact that
## K!(N-K)!/(N+1)! = beta(K+1,N-K+1)
## and the numerically robust octave-function betaln()=ln(beta()):
## ln pdf(f|N,K) = -betaln(K+1,N-K+1) + K ln(f) + (N-K) ln(1-f)
##
## Some useful properties of this posterior PDF are:
## the maximum-posterior estimate (MPE) for the rate f is
## fMPE = K/N,
## the expectation is
## fE = E[f|N,K] = (K+1)/(N+2)
## and the variance
## var[f] = (K+1)*(N-K+1)/( (N+3)*(N+2)^2)
##        = Ef * (1-Ef) / (N+3)
## which in the large-N limit leads to
## fE ~ fMPE,
## var[f] ~ 1/N * fMPE * (1 - fMPE)
function pdf = binomialRatePDF ( f, N, K )

  [errorcode, fi, Ni, Ki] = common_size ( f, N, K );
  assert ( errorcode == 0, "Input vectors {f,N,K} need to have consistent sizes (ie scalar or equal-size)" );

  logpdf = - betaln ( Ki + 1, Ni - Ki + 1 ) + Ki .* log(fi) + (Ni - Ki) .* log( 1 - fi);
  pdf = e.^logpdf;
  ## analytic continuation: replace all NaNs by (N+1) to deal with the special points (f=0,K=0) and (f=1,K=N):
  ## these give NaNs but have the exact value N+1
  indsNaN = find ( isnan(pdf) );
  pdf (indsNaN) = Ni(indsNaN) +1;
endfunction
