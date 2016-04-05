## Copyright (C) 2015 Karl Wette
##
## This program is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Set a threshold on the histogram probability of each bin; bins with
## probability below the threshold have their count set to zero.
## Usage:
##   thgrm = thresholdHist(hgrm, pth)
## where:
##   thgrm = thresholded histogram class
##   hgrm  = original histogram class
##   pth   = probability threshold

function hgrm = thresholdHist(hgrm, pth)

  ## check input
  assert(isHist(hgrm));
  assert(isscalar(pth) && 0 < pth && pth <= 1);

  ## get histogram probabilities
  prob = histProbs(hgrm);

  ## zero count in bins with probability below threshold
  hgrm.counts(find(prob < pth)) = 0;

endfunction
