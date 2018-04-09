## Copyright (C) 2014 David Keitel
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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{minCoverFreq}, @var{maxCoverFreq} ] =} CWSignalCoveringBand ( @var{fkdot_starttime}, @var{fkdotband_starttime}, @var{fkdot_endtime}, @var{fkdotband_endtime} )
##
## based on @command{XLALCWSignalCoveringBand()} by K. Wette, R. Prix
## Determines a frequency band which covers the frequency evolution of a band of CW signals between two GPS times.
## The calculation accounts for the spin evolution of the signals, and the maximum possible Dopper modulation due to detector motion.
## binary orbital motion, which is supported by @command{XLALCWSignalCoveringBand()}, is dropped here.
## contrary to XLALCWSignalCoveringBand, fkdot and fkdotband must be pre-extrapolated to starttime, endtime
##
## @end deftypefn

function [minCoverFreq, maxCoverFreq] = CWSignalCoveringBand  ( fkdot_starttime, fkdotband_starttime, fkdot_endtime, fkdotband_endtime )

  ## Determine the minimum and maximum frequencies covered
  minCoverFreq = min( fkdot_starttime(1), fkdot_endtime(1) );
  maxCoverFreq = max( fkdot_starttime(1) + fkdotband_starttime(1), fkdot_endtime(1) + fkdotband_endtime(1) );

  ## Extra frequency range needed due to detector motion, per unit frequency
  ## Maximum value of the time derivative of the diurnal and (Ptolemaic) orbital phase, plus 5% for luck
  c = 299792458;
  AU = 1.4959787066e11;
  Rearth = 6.378140e6;
  sidyr = 31558149.8;
  sidday = 86164.09053;
  extraPerFreq = 1.05 * 2.0 * pi / c * ( (AU/sidyr) + (Rearth/sidday) );

  ## Expand frequency range
  minCoverFreq *= 1.0 - extraPerFreq;
  maxCoverFreq *= 1.0 + extraPerFreq;

endfunction ## CWSignalCoveringBand()

%!test
%!  [minCoverFreq, maxCoverFreq] = CWSignalCoveringBand([100, -1e-8], [1e-2, 1e-11], [99, -1e-8], [1e-2, 1e-11]);
%!  assert([minCoverFreq, maxCoverFreq], [98.990, 100.02], 1e-2)
