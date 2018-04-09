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
## @deftypefn {Function File} {@var{pdf} =} binomialRatePDF ( @var{f}, @var{N}, @var{K} )
##
## Return the posterior pdf(@var{f}|@var{N},@var{K}) for the true 'rate' @var{f} given a drawing
## experiment with @var{K} "successful" results out of @var{N} trials, assuming a
## uniform prior on @var{f} in [0,1], which yields
##
## pdf(@var{f}|@var{N},@var{K}) = (@var{N}+1)!/(@var{K}! (@var{N}-@var{K})!) * @var{f}^@var{K} * (1-@var{f})^(@var{N}-@var{K})
##
## This expression would be numerically overflowing very
## easily when @var{N},@var{K}>>1, and so we use the fact that
##
## K!(@var{N}-@var{K})!/(@var{N}+1)! = beta(@var{K}+1,@var{N}-@var{K}+1)
##
## and the numerically robust octave-function betaln()=ln(beta()):
##
## ln pdf(@var{f}|@var{N},@var{K}) = -betaln(@var{K}+1,@var{N}-@var{K}+1) + @var{K} ln(@var{f}) + (@var{N}-@var{K}) ln(1-@var{f})
##
## Some useful properties of this posterior PDF are:
## @itemize
## @item
## the maximum-posterior estimate (MPE) for the rate @var{f} is
## fMPE = @var{K}/@var{N},
##
## @item
## the expectation is
## fE = E[@var{f}|@var{N},@var{K}] = (@var{K}+1)/(@var{N}+2)
##
## @item
## and the variance
## var[@var{f}] = (@var{K}+1)*(@var{N}-@var{K}+1)/( (@var{N}+3)*(@var{N}+2)^2)
## = Ef * (1-Ef) / (@var{N}+3)
## which in the large-@var{N} limit leads to
## fE ~ fMPE,
## var[@var{f}] ~ 1/@var{N} * fMPE * (1 - fMPE)
## @end itemize
##
## @end deftypefn

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

%!assert(binomialRatePDF(0:0.1:1, 10, 7), [0.000 0.000 0.009 0.099 0.467 1.289 2.365 2.935 2.215 0.631 0.000], 1e-3)
