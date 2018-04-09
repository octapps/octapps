## Copyright (C) 2006 Reinhard Prix
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
## @deftypefn {Function File} { [ @var{NN}, @var{XX} ] =} normHist ( @var{data}, @var{bins} )
##
## compute a pdf-normalized histogram (i.e. the *integral* is 1)
##
## With one vector input argument, plot a histogram of the values with
## 10 @var{bins}.  The range of the histogram @var{bins} is determined by the
## range of the @var{data}.  With one matrix input argument, plot a
## histogram where each bin contains a bar per input column.
##
## Given a second scalar argument, use that as the number of @var{bins}.
##
## Given a second vector argument, use that as the centers of the
## bins, with the width of the @var{bins} determined from the adjacent
## values in the vector.
##
## @end deftypefn

function [NN, XX] = normHist ( data, bins )

  if ( nargin == 1 )
    bins = 10;
  endif

  [NN, XX] = hist ( data, bins, 1 );

  ## normalize as a "pdf", i.e. such that 1 = sum_i NN_i * dXX_i
  if ( isscalar ( bins ) )
    dx = (max(XX) - min(XX)) / bins;
  else
    mids = (bins(1:end-1) + bins(2:end)) / 2;
    boundaries = [ bins(1), mids, bins(end) ];
    dx = diff ( boundaries );
  endif

  NN ./= dx;

endfunction

%!assert(normHist(0:0.001:100), 0.011 * ones(1, 10), 1e-3)
