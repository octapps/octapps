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
## @deftypefn {Function File} {@var{fDH} =} falseDismissal_HoughF ( @var{nth}, @var{Nseg}, @var{Fth}, @var{SNR0sq} )
##
## compute Hough-on-Fstat false-dismissal probability fDH for given number of segments @var{Nseg},
## a threshold on segment-crossings @var{nth}, an F-statistic threshold per segment @var{Fth},
## and the optimal signal SNR^2 per segment @var{SNR0sq}, which is assumed constant across all segments.
##
## A false-dismissal is defined as n < @var{nth} segments crossing the threshold @var{Fth} in the
## presence of a signal
##
## @heading Note
##
## all arguments need to be scalars, use @command{arrayfun()} or @command{cellfun()} to iterate thisover vectors of arguments
##
## @end deftypefn

function fDH = falseDismissal_HoughF ( nth, Nseg, Fth, SNR0sq )
  fn = "falseDismissal_HoughF()";

  if ( !isscalar(nth) || !isscalar(Nseg) || !isscalar(Fth) || !isscalar(SNR0sq) )
    error ("%s: All input arguments need to be scalars! nth (%d), Neg (%d), Fth (%d), SNR0sq (%d)\n",
           fn, length(nth), length(Nseg), length(Fth), length(SNR0sq) );
  endif

  ## eta = threshold-crossing probability for one segment
  fDF = ChiSquare_cdf( 2*Fth, 4, SNR0sq );
  eta = 1 - fDF;

  ni  = [0:(nth-1)];
  bci = bincoeff (Nseg, ni);
  ## printf ("%s: SNR0sq = %g, nth = %d, Fth = %g, eta = %g\n", fn, SNR0sq, nth, Fth, eta );
  logpni = log(bci) + ni * log(eta) + (Nseg - ni) * log1p( - eta );

  fDH = sum ( exp ( logpni ) );

endfunction

%!assert(falseDismissal_HoughF(11, 100, 5.5, 2.2), 0.303, 1e-3)
%!assert(falseDismissal_HoughF(18, 100, 5.5, 2.2), 0.939, 1e-3)
