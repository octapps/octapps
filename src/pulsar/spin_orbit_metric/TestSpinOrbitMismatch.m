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

## Test spin-orbit mismatch prediction using simulated parameter offsets.
## Usage:
##   results = TestSpinOrbitMismatch(...)
## Options:
##   Tdays              = coherent time span (days)
##   mismatch           = mismatch to use when generating offsets
##   ptolemaic          = use Ptolemaic orbits?
##   detectors          = comma-separated detector names
##   num_spindowns      = number of spindowns
##   max_frequency      = maximum frequency (Hertz)
##   num_ref_times      = number of reference times over 1yr to test
##   num_trials_per_ref = number of MC trials per reference time
##   so_mismatch_frac   = bias in spin-orbit mismatch (default:none)
##   output_file        = output file to save results to

function results = TestSpinOrbitMismatch(varargin)

  ## Parse options.
  opts = parseOptions(varargin,
                      {"Tdays", "numeric,scalar"},
                      {"mismatch", "numeric,scalar", 0.5},
                      {"ptolemaic", "logical", true},
                      {"detectors", "char", "H1"},
                      {"num_spindowns", "numeric,scalar", 1},
                      {"max_frequency", "numeric,scalar", 100.0},
                      {"num_ref_times", "numeric,scalar", 10},
                      {"num_trials_per_ref", "numeric,scalar", 10},
                      {"so_mismatch_frac", "numeric,scalar", -1},
                      {"output_file", "char", []},
                      []);

  ## Check input.
  assert(num_ref_times > 0);
  assert(num_trials_per_ref > 0);

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

  ## Equally spaced reference times over a year.
  if num_ref_times == 1
    ref_time_offsets = 0;
  else
    ref_time_offsets = LAL_DAYSID_SI * linspace(-182.625, 182.625, num_ref_times);
  endif

  ## Create detector info.
  detNames = CreateStringVector(strsplit(detectors, ","));
  dets = new_MultiDetectorInfo;
  ParseMultiDetectorInfo(dets, detNames, []);

  ## Time span.
  Tspan = LAL_DAYSID_SI * Tdays;

  ## Frequency/spindown point about which to test.
  f0 = zeros(1+num_spindowns, 1);
  f0(1) = max_frequency;

  ## Store results.
  results = struct;
  results.opts = opts;
  results.ref_time_offset = [];
  results.hist_log_rel_underest_wrt_ss = newHist;
  results.hist_log_rel_overest_wrt_ss = newHist;
  results.hist_log_rel_underest_wrt_so = newHist;
  results.hist_log_rel_overest_wrt_so = newHist;

  ## Iterate over reference time offsets.
  for n = 1:length(ref_time_offsets)

    ## Reference time.
    ref_time = mid_edat_time + ref_time_offsets(n);

    ## Generate super-sky metric.
    g_ss = SuperskyMetric(ptolemaic, Tspan, ref_time, edat, dets, max_frequency, num_spindowns);

    ## Generate spin-orbit metric.
    so_type = SOMT_SPIN + SOMT_REDUCED + SOMT_ORBIT;
    if ptolemaic
      so_type += SOMT_PTOLEMAIC;
    endif
    so_ret = CreateSpinOrbitMetric(so_type, Tspan, ref_time, edat, dets, max_frequency, num_spindowns);
    g_so = SpinOrbitGetMetric(so_ret).data(:,:);

    ## Split spin-orbit metric into spin and remainder blocks
    g_so_ss = g_so(1:2,1:2);
    g_so_rs = g_so(3:end,1:2);
    g_so_rr = g_so(3:end,3:end);

    ## Eigen-decompose spin-orbit metric.
    [V_so, D_so] = eig(g_so);
    [V_so_s, D_so_s] = eig(g_so_ss);
    [V_so_r, D_so_r] = eig(g_so_rr);

    ## Store results.
    results.ref_time_offset(n).ref_time.gpsSeconds = ref_time.gpsSeconds;
    results.ref_time_offset(n).ref_time.gpsNanoSeconds = ref_time.gpsNanoSeconds;
    results.ref_time_offset(n).g_ss = g_ss;
    results.ref_time_offset(n).g_so = g_so;

    ## Generate random offsets and calculate mismatches
    hist_log_rel_underest_wrt_ss = newHist;
    hist_log_rel_overest_wrt_ss = newHist;
    hist_log_rel_underest_wrt_so = newHist;
    hist_log_rel_overest_wrt_so = newHist;
    for i = 1:num_trials_per_ref

      ## Generate random super-sky parameter space offsets.
      [ss1, ss2] = RandomSuperskyMismatch(mismatch, g_ss, f0);

      ## Calculate super-sky mismatch w.r.t super-sky offsets.
      dss = ss1 - ss2;
      mu_ss_wrt_ss = dot(dss, g_ss * dss);

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
      mu_so_wrt_ss = dot(dso, g_so * dso);

      ## Generate random spin-orbit parameter space offset:
      if so_mismatch_frac < 0

        ## Generate unrestricted offsets.
        dso = V_so * inv(sqrt(D_so)) * randn(length(dso), 1);
        dso .*= sqrt(mismatch ./ dot(dso, g_so * dso));

      else

        ## Generate random mismatch for the spin part
        if so_mismatch_frac == 0
          mu_s = rand * mismatch;
        else
          mu_s = so_mismatch_frac * mismatch;
        endif

        ## Generate random spin parameter space offset,
        ## with a mismatch of mu_s
        dso_s = V_so_s * inv(sqrt(D_so_s)) * randn(2, 1);
        dso_s .*= sqrt(mu_s ./ dot(dso_s, g_so_ss * dso_s));

        ## Adjustment for remaining offsets so that overall
        ## mismatch is correct, accounting for metric cross-terms.
        ## See RandomSuperskyMismatch() for derivation.
        dso_ro = g_so_rr \ (g_so_rs * dso_s);
        mu_r = mismatch - mu_s + dot(dso_ro, g_so_rr * dso_ro);

        ## Generate random remainder parameter space offset,
        ## with a mismatch of mu_r
        dso_r = V_so_r * inv(sqrt(D_so_r)) * randn(length(dso)-2, 1);
        dso_r .*= sqrt(mu_r ./ dot(dso_r, g_so_rr * dso_r));

        ## Adjust for metric cross-terms.
        dso_r -= dso_ro;

        ## Create final offset.
        dso = [dso_s; dso_r];

      endif
      so2.data = so1.data + dso;

      ## Calculate spin-orbit mismatch w.r.t spin-orbit offsets.
      mu_so_wrt_so = dot(dso, g_so * dso);

      ## Transform from spin-orbit to super-sky coordinates.
      [n1r, f1r] = SpinOrbitMetricCoordToSupersky(so_ret, so1, sign(ss1(3)));
      [n2r, f2r] = SpinOrbitMetricCoordToSupersky(so_ret, so2, sign(ss1(3)));
      ss1r = [n1r; f1r(1:1+num_spindowns)];
      ss2r = [n2r; f2r(1:1+num_spindowns)];

      ## Calculate super-sky mismatch w.r.t spin-orbit offsets.
      dssr = ss1r - ss2r;
      mu_ss_wrt_so = dot(dssr, g_ss * dssr);

      ## Store histograms of relative differences.
      rel_diff_wrt_ss = (mu_so_wrt_ss - mu_ss_wrt_ss) / mu_ss_wrt_ss;
      if rel_diff_wrt_ss < 0
        hist_log_rel_underest_wrt_ss = addDataToHist(hist_log_rel_underest_wrt_ss, log10(abs(rel_diff_wrt_ss)), 0.1);
      else
        hist_log_rel_overest_wrt_ss = addDataToHist(hist_log_rel_overest_wrt_ss, log10(abs(rel_diff_wrt_ss)), 0.1);
      endif
      rel_diff_wrt_so = (mu_ss_wrt_so - mu_so_wrt_so) / mu_so_wrt_so;
      if rel_diff_wrt_so < 0
        hist_log_rel_underest_wrt_so = addDataToHist(hist_log_rel_underest_wrt_so, log10(abs(rel_diff_wrt_so)), 0.1);
      else
        hist_log_rel_overest_wrt_so = addDataToHist(hist_log_rel_overest_wrt_so, log10(abs(rel_diff_wrt_so)), 0.1);
      endif

    endfor

    ## Store results.
    results.ref_time_offset(n).hist_log_rel_underest_wrt_ss = hist_log_rel_underest_wrt_ss;
    results.ref_time_offset(n).hist_log_rel_overest_wrt_ss = hist_log_rel_overest_wrt_ss;
    results.hist_log_rel_underest_wrt_ss = addHists(results.hist_log_rel_underest_wrt_ss, hist_log_rel_underest_wrt_ss);
    results.hist_log_rel_overest_wrt_ss = addHists(results.hist_log_rel_overest_wrt_ss, hist_log_rel_overest_wrt_ss);
    results.ref_time_offset(n).hist_log_rel_underest_wrt_so = hist_log_rel_underest_wrt_so;
    results.ref_time_offset(n).hist_log_rel_overest_wrt_so = hist_log_rel_overest_wrt_so;
    results.hist_log_rel_underest_wrt_so = addHists(results.hist_log_rel_underest_wrt_so, hist_log_rel_underest_wrt_so);
    results.hist_log_rel_overest_wrt_so = addHists(results.hist_log_rel_overest_wrt_so, hist_log_rel_overest_wrt_so);

  endfor

  ## Store results.
  results.hist_log_rel_error_wrt_ss = addHists(results.hist_log_rel_underest_wrt_ss, results.hist_log_rel_overest_wrt_ss);
  results.hist_log_rel_error_wrt_so = addHists(results.hist_log_rel_underest_wrt_so, results.hist_log_rel_overest_wrt_so);

  ## Save results.
  if !isempty(output_file)
    save("-zip", output_file, "-struct", "results");
  endif

endfunction
