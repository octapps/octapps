function TestSpinOrbitMismatch(varargin)

  ## Parse options.
  parseOptions(varargin,
               {"mismatch", "numeric,scalar", 0.5},
               {"ptolemaic", "logical", true},
               {"num_spindowns", "numeric,scalar", 1},
               {"max_frequency", "numeric,scalar", 100},
               {"num_trials", "numeric,scalar", 10}
               );

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
  Tspan = LAL_DAYSID_SI * 7;

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
    so1 = SpinOrbitMetricCoordFromSupersky(so_ret, n1, f1, ref_time);
    so2 = SpinOrbitMetricCoordFromSupersky(so_ret, n2, f2, ref_time);

    ## Calculate spin-orbit mismatch w.r.t super-sky offsets.
    dso = so1.data - so2.data;
    mu_so_wrt_ss(i) = dot(dso, g_so * dso);

    ## Generate random spin-orbit parameter space offset.
    dso = inv(sqrt(D_so)) * randn(length(dso), 1);
    dso .*= sqrt(mismatch ./ dot(dso, D_so * dso));
    dso = V_so * dso;
    so2.data = so1.data + dso;

    ## Calculate spin-orbit mismatch w.r.t spin-orbit offsets.
    mu_so_wrt_so(i) = dot(dso, g_so * dso);

    ## Transform from spin-orbit to super-sky coordinates.
    [n1r, f1r] = SpinOrbitMetricCoordToSupersky(so_ret, so1, sign(ss1(3)));
    [n2s, f2s] = SpinOrbitMetricCoordToSupersky(so_ret, so2, -1);
    [n2n, f2n] = SpinOrbitMetricCoordToSupersky(so_ret, so2, +1);

    ss1r = [n1r; f1r(1:1+num_spindowns)];
    ss2s = [n2s; f2s(1:1+num_spindowns)];
    ss2n = [n2n; f2n(1:1+num_spindowns)];

    dsss = ss1r - ss2s;
    dssn = ss1r - ss2n;

    mu_ss_wrt_so(i) = min(dot(dsss, g_ss * dsss), dot(dssn, g_ss * dssn));

  endfor

  relerr_wrt_ss = abs(mu_ss_wrt_ss - mu_so_wrt_ss) ./ mu_ss_wrt_ss;
  min(relerr_wrt_ss)
  mean(relerr_wrt_ss)
  max(relerr_wrt_ss)

  relerr_wrt_so = abs(mu_ss_wrt_so - mu_so_wrt_so) ./ mu_ss_wrt_so;
  min(relerr_wrt_so)
  mean(relerr_wrt_so)
  max(relerr_wrt_so)

endfunction
