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

function [relerr_wrt_ss, relerr_wrt_so] = TestSpinOrbitMismatch(varargin)

  ## Parse options.
  parseOptions(varargin,
               {"Tdays", "numeric,scalar"},
               {"mismatch", "numeric,scalar", 0.5},
               {"ptolemaic", "logical", true},
               {"num_spindowns", "numeric,scalar", 1},
               {"max_frequency", "numeric,scalar", 100.0},
               {"num_trials", "numeric,scalar", 100},
               {"so_dist_bias", "numeric,vector", []},
               []);

  ## Load LAL libraries.
  lal;
  lalpulsar;
  lal.lalcvar.lalDebugLevel = 1;

  ## Load ephemerides.
  try
    edat = InitBarycenter("earth05-09.dat", "sun05-09.dat");
  catch
    error("%s: Could not load ephemerides", funcName);
  end_try_catch

  ## Mid-time of 05-09 ephemeris files
  mid_edat_time = LIGOTimeGPS(868284000);

  ## Create detector info.
  dets = new_MultiDetectorInfo;
  dets.sites{1} = lalcvar.lalCachedDetectors{1+lal.LAL_LHO_4K_DETECTOR};
  dets.length = 1;
  dets.detWeights(1:dets.length) = 1;

  ## Reference time.
  ref_time = mid_edat_time;

  ## Time span.
  Tspan = LAL_DAYSID_SI * Tdays;

  ## Frequency/spindown point about which to test.
  f0 = zeros(1+num_spindowns, 1);
  f0(1) = max_frequency;

  ## Generate super-sky metric.
  g_ss = SuperskyMetric(ptolemaic, Tspan, ref_time, edat, dets, max_frequency, num_spindowns);

  ## Generate spin-orbit metric.
  so_type = SOMT_SPIN + SOMT_REDUCED + SOMT_ORBIT;
  if ptolemaic
    so_type += SOMT_PTOLEMAIC;
  endif
  so_ret = CreateSpinOrbitMetric(so_type, Tspan, ref_time, edat, dets, max_frequency, num_spindowns);
  g_so = SpinOrbitGetMetric(so_ret).data(:,:);

  ## Eigen-decompose spin-orbit metric.
  [V_so, D_so] = eig(g_so);

  ## Generate random offsets and calculate mismatches
  mu_ss_wrt_ss = mu_so_wrt_ss = zeros(num_trials, 1);
  mu_ss_wrt_so = mu_so_wrt_so = zeros(num_trials, 1);
  for i = 1:num_trials

    ## Generate random super-sky parameter space offsets.
    [ss1, ss2] = RandomSuperskyMismatch(mismatch, g_ss, f0);

    ## Calculate super-sky mismatch w.r.t super-sky offsets.
    dss = ss1 - ss2;
    mu_ss_wrt_ss(i) = dot(dss, g_ss * dss);

    ## Transform from super-sky to spin-orbit coordinates.
    n1 = ss1(1:3);
    n2 = ss2(1:3);
    f1 = ss1(4:end);
    f2 = ss2(4:end);
    f1(end+1:PULSAR_MAX_SPINS) = 0;
    f2(end+1:PULSAR_MAX_SPINS) = 0;
    so1 = SpinOrbitMetricCoordFromSupersky(so_ret, n1, f1);
    so2 = SpinOrbitMetricCoordFromSupersky(so_ret, n2, f2);

    ## Calculate spin-orbit mismatch w.r.t super-sky offsets.
    dso = so1.data - so2.data;
    mu_so_wrt_ss(i) = dot(dso, g_so * dso);

    ## Generate random spin-orbit parameter space offset.
    dso = V_so * inv(sqrt(D_so)) * randn(length(dso), 1);
    if !isempty(so_dist_bias)

      ## Bias distribution of random spin-orbit offsets.
      dso = diag(so_dist_bias) * dso;

    endif
    dso .*= sqrt(mismatch ./ dot(dso, g_so * dso));
    so2.data = so1.data + dso;

    ## Calculate spin-orbit mismatch w.r.t spin-orbit offsets.
    mu_so_wrt_so(i) = dot(dso, g_so * dso);

    ## Transform from spin-orbit to super-sky coordinates.
    [n1r, f1r] = SpinOrbitMetricCoordToSupersky(so_ret, so1, sign(ss1(3)));
    [n2r, f2r] = SpinOrbitMetricCoordToSupersky(so_ret, so2, sign(ss1(3)));
    ss1r = [n1r; f1r(1:1+num_spindowns)];
    ss2r = [n2r; f2r(1:1+num_spindowns)];

    ## Calculate super-sky mismatch w.r.t spin-orbit offsets.
    dssr = ss1r - ss2r;
    mu_ss_wrt_so(i) = dot(dssr, g_ss * dssr);

  endfor

  ## Calculate relative errors.
  relerr_wrt_ss = abs(mu_ss_wrt_ss - mu_so_wrt_ss) ./ mu_ss_wrt_ss;
  relerr_wrt_so = abs(mu_so_wrt_so - mu_ss_wrt_so) ./ mu_so_wrt_so;

  ## Print some statistics.
  printf("Rel. error w.r.t. super-sky : min=%0.3e, mean=%0.3e, max=%0.3e\n", min(relerr_wrt_ss), mean(relerr_wrt_ss), max(relerr_wrt_ss));
  printf("Rel. error w.r.t. spin-orbit: min=%0.3e, mean=%0.3e, max=%0.3e\n", min(relerr_wrt_so), mean(relerr_wrt_so), max(relerr_wrt_so));

endfunction
