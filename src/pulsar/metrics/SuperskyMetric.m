## Copyright (C) 2012 Karl Wette
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

## Compute the super-sky phase metric, using functions from LALPulsar,
## in coordinates nx,ny,nz (|n|=1) and f,fd,... (SI units)
## Usage:
##    g_ss = SuperskyMetric(ptole, Tspan, refTime, edat, detInfo, fmax, nspin)
## where:
##    g_ss    = super-sky phase metric
##    ptole   = whether to use Ptolemaic orbits (true/false)
##    Tspan   = observation time-span (seconds)
##    refTime = reference time at mid-point (LIGOTimeGPS)
##    edat    = ephemerides (EphemerisData)
##    detInfo = detector info (MultiDetectorInfo)
##    fmax    = maximum search frequency (Hertz)
##    nspin   = number of spindowns
function g_ss = SuperskyMetric(ptole, Tspan, refTime, edat, detInfo, fmax, nspin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## create metric parameters struct for super-sky metric
  metricpar = new_DopplerMetricParams;

  ## create coordinate system
  dim = 1;
  metricpar.coordSys.coordIDs(dim++) = DOPPLERCOORD_N3X_EQU;
  metricpar.coordSys.coordIDs(dim++) = DOPPLERCOORD_N3Y_EQU;
  metricpar.coordSys.coordIDs(dim++) = DOPPLERCOORD_N3Z_EQU;
  if floor(nspin) != nspin || nspin < 0 || nspin > 3
    error("%s: number of spindowns must be an integer between 0 to 3", funcName);
  endif
  if nspin >= 0
    metricpar.coordSys.coordIDs(dim++) = DOPPLERCOORD_FREQ_NAT;
  endif
  if nspin >= 1
    metricpar.coordSys.coordIDs(dim++) = DOPPLERCOORD_F1DOT_NAT;
  endif
  if nspin >= 2
    metricpar.coordSys.coordIDs(dim++) = DOPPLERCOORD_F2DOT_NAT;
  endif
  metricpar.coordSys.dim = dim-1;

  ## set detector information
  metricpar.detInfo = detInfo;

  ## set detector motion
  if ptole
    metricpar.detMotionType = DETMOTION_SPIN_PTOLEORBIT;
  else
    metricpar.detMotionType = DETMOTION_SPIN_ORBIT;
  endif
  metricpar.approxPhase = true;

  ## set metric type to return
  metricpar.metricType = METRIC_TYPE_PHASE;

  ## do not project coordinates
  metricpar.projectCoord = -1;

  ## set ametricparlitude and Doppler parameters
  metricpar.signalParams.Amp.h0 = 1;
  metricpar.signalParams.Doppler.fkdot(1) = fmax;

  ## set time span
  metricpar.Tspan = Tspan;

  ## set start and reference times
  metricpar.signalParams.Doppler.refTime = refTime;
  metricpar.startTime = refTime;
  GPSAdd(metricpar.startTime, -0.5 * Tspan);

  ## calculate super-sky phase metric
  try
    [dpm_M, dpm_err] = DopplerPhaseMetric(metricpar, edat);
  catch
    error("%s: Could not calculate phase metric", funcName);
  end_try_catch
  g_ss = dpm_M.data(:,:);

  ## calculate scaling constants for super-sky metric
  ss_scale = zeros(4 + nspin, 1);
  ss_scale(1:3) = LAL_TWOPI * fmax * LAL_AU_SI / LAL_C_SI;
  for s = 0:nspin
    ss_scale(4+s) = LAL_TWOPI * (Tspan/2)^(s+1) / factorial(s+1);
  endfor
  g_ss = diag(ss_scale) * g_ss * diag(ss_scale);

endfunction
