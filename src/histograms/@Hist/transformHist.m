## Copyright (C) 2011, 2013 Karl Wette
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
## @deftypefn {Function File} {@var{hgrm} =} transformHist ( @var{hgrm}, @var{F}, [ @var{err} ] )
##
## Transform the contents of a histogram.
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item F
## function to apply to histogram samples:
## @itemize
## @item
## should accept column vectors as inputs and return
## an array whose columns are vectorised outputs
## @item
## number of input/output arguments must match
## histogram dimensionality
## @end itemize
##
## @item err
## convergence requirement on histogram (default = 1e-2)
##
## @end table
##
## @end deftypefn

function thgrm = transformHist(hgrm, F, err = 1e-2)

  ## check input
  assert(isHist(hgrm));
  dim = length(hgrm.bins);

  ## copy histogram, but zero out contents
  thgrm = shgrm = hgrm;
  thgrm.counts = shgrm.counts = zeros(size(hgrm.counts));

  ## draw samples from histogram, add to sample histogram,
  ## transform them, add them to transformed histogram, and
  ## continue until original histogram equals sampled histogram
  N = 1e6;
  do

    ## draw samples from histogram, add to sample histogram
    x = drawFromHist(hgrm, N);
    shgrm = addDataToHist(shgrm, x);

    ## transform samples
    Fargs = mat2cell(x, N, ones(1, dim));
    tx = feval(F, Fargs{:});
    assert(ismatrix(tx));
    assert(size(tx) == size(x));

    ## add transformed samples to transformed histogram
    thgrm = addDataToHist(thgrm, tx);

    ## calculate distance between original and sample histograms
    histerr = histDistance(hgrm, shgrm);

  until histerr < err

endfunction

## create 1-D histograms for testing
%!shared hgrmA, hgrmA1, hgrmA2, hgrmA3
%!  hgrmA = hgrmA1 = hgrmA2 = hgrmA3 = Hist(1, {"lin", "dbin", 0.1});
%!  N = 1e6;
%!  do
%!    x = randn(N, 1);
%!    oldhgrmA = hgrmA;
%!    hgrmA = addDataToHist(hgrmA, x);
%!    hgrmA1 = addDataToHist(hgrmA1, abs(x));
%!    hgrmA2 = addDataToHist(hgrmA2, x.^2 - 3);
%!    hgrmA3 = addDataToHist(hgrmA3, sin(x));
%!    histerr = histDistance(oldhgrmA, hgrmA);
%!  until histerr < 1e-2

## test 1-D histograms
%!test
%!  t_hgrmA = transformHist(hgrmA, @(x) x);
%!  assert(histDistance(hgrmA, t_hgrmA) < 0.01);
%!test
%!  t_hgrmA1 = transformHist(hgrmA, @(x) abs(x));
%!  assert(histDistance(hgrmA1, t_hgrmA1) < 0.05);
%!test
%!  t_hgrmA2 = transformHist(hgrmA, @(x) x.^2 - 3);
%!  assert(histDistance(hgrmA2, t_hgrmA2) < 0.05);
%!test
%!  t_hgrmA3 = transformHist(hgrmA, @(x) sin(x));
%!  assert(histDistance(hgrmA3, t_hgrmA3) < 0.05);

## create 2-D histograms for testing
%!shared hgrmB, hgrmB1, hgrmB2, hgrmB3
%!  hgrmB = hgrmB1 = hgrmB2 = hgrmB3 = Hist(2, {"lin", "dbin", 0.1}, {"log", "minrange", 1.0, "binsper10", 8});
%!  N = 1e7;
%!  do
%!    x = randn(N, 1);
%!    y = sign(x) .* 10.^(-1 + 3*rand(N, 1));
%!    oldhgrmB = hgrmB;
%!    hgrmB = addDataToHist(hgrmB, [x, y]);
%!    hgrmB1 = addDataToHist(hgrmB1, [abs(x), 10.*y]);
%!    hgrmB2 = addDataToHist(hgrmB2, [x.^2 - 3, y.^3]);
%!    hgrmB3 = addDataToHist(hgrmB3, [sin(x), cos(y)]);
%!    histerr = histDistance(oldhgrmB, hgrmB);
%!  until histerr < 1e-2

## test 2-D histograms
%!test
%!  t_hgrmB = transformHist(hgrmB, @(x,y) [x, y]);
%!  assert(histDistance(hgrmB, t_hgrmB) < 0.05)
%!test
%!  t_hgrmB1 = transformHist(hgrmB, @(x,y) [abs(x), 10.*y]);
%!  assert(histDistance(hgrmB1, t_hgrmB1) < 0.1);
%!test
%!  t_hgrmB2 = transformHist(hgrmB, @(x,y) [x.^2 - 3, y.^3]);
%!  assert(histDistance(hgrmB2, t_hgrmB2) < 0.1);
%!test
%!  t_hgrmB3 = transformHist(hgrmB, @(x,y) [sin(x), cos(y)]);
%!  assert(histDistance(hgrmB3, t_hgrmB3) < 0.1)'
