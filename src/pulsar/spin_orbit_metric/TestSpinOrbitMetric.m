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

function [rms_errors, metrics, ptmetrics] = TestSpinOrbitMetric(Tdays)

  ## check input
  assert(isvector(Tdays));

  ## load LAL libraries
  lal;
  lalpulsar;
  lalcvar.lalDebugLevel = 1;

  ## get ephemerides
  try
    edat = InitBarycenter("earth05-09.dat", "sun05-09.dat");
  catch
    error("%s: Could not load ephemerides", funcName);
  end_try_catch

  ## create metric parameters struct
  mp = new_DopplerMetricParams;

  ## create coordinate system
  mp.coordSys.coordIDs(1) = DOPPLERCOORD_KX;
  mp.coordSys.coordIDs(2) = DOPPLERCOORD_KY;
  mp.coordSys.coordIDs(3) = DOPPLERCOORD_MX;
  mp.coordSys.coordIDs(4) = DOPPLERCOORD_MY;
  mp.coordSys.coordIDs(5) = DOPPLERCOORD_W2;
  mp.coordSys.coordIDs(6) = DOPPLERCOORD_W1;
  mp.coordSys.coordIDs(7) = DOPPLERCOORD_W0;
  mp.coordSys.dim = dim = 7;

  ## set detectors
  mp.detInfo.sites{1} = lalcvar.lalCachedDetectors{1+LAL_LHO_4K_DETECTOR};
  mp.detInfo.length = 1;
  mp.detInfo.detWeights(1:mp.detInfo.length) = 1;

  ## set detector motion
  mp.detMotionType = DETMOTION_SPIN_PTOLEORBIT;
  mp.approxPhase = true;

  ## set metric type to return
  mp.metricType = METRIC_TYPE_PHASE;

  ## do not project coordinates
  mp.projectCoord = -1;

  ## set amplitude and Doppler parameters
  mp.signalParams.Amp.h0 = 1;
  mp.signalParams.Doppler.fkdot(1) = fmax = 100;

  ## loop over observation times
  metrics = ptmetrics = zeros(dim, dim, length(Tdays));
  page_screen_output(0);
  for n = 1:length(Tdays);
    printf("%i ", length(Tdays) - n);

    ## set time span
    mp.Tspan = LAL_DAYSID_SI * Tdays(n);

    ## set start and reference times
    mp.startTime.gpsSeconds = 790000000;
    mp.signalParams.Doppler.refTime = mp.startTime + mp.Tspan / 2;

    ## calculate phase metric
    try
      mret = DopplerFstatMetric(mp, edat);
    catch
      error("%s: Could not calculate phase metric", funcName);
    end_try_catch
    metrics(:,:,n) = DiagNormalizeMetric(mret.g_ij).data;

    ## calculate phase metric, Ptolemaic approx
    ptmetrics(:,:,n) = SpinOrbitPtoleMetric(mp.coordSys.coordIDs(1:dim), mp.detInfo.sites{1}, mp.signalParams.Doppler.refTime, mp.Tspan);

  endfor
  printf("\n");
  page_screen_output(1);

  ## get r.m.s. differences
  rms_errors = squeeze(sqrt(sum(sum(abs(metrics - ptmetrics).^2, 1), 2) / dim^2));

endfunction
