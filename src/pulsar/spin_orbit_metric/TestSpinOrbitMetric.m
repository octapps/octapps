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
mp.coordSys.coordIDs(1) = DOPPLERCOORD_KAPPA_S;
mp.coordSys.coordIDs(2) = DOPPLERCOORD_SIGMA_S;
mp.coordSys.coordIDs(3) = DOPPLERCOORD_KAPPA_O;
mp.coordSys.coordIDs(4) = DOPPLERCOORD_SIGMA_O;
mp.coordSys.coordIDs(5) = DOPPLERCOORD_OMEGA_2;
mp.coordSys.coordIDs(6) = DOPPLERCOORD_OMEGA_1;
mp.coordSys.coordIDs(7) = DOPPLERCOORD_OMEGA_0;
mp.coordSys.dim = dim = 7;

# set detectors
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
days = linspace(0.5, 365, 20);
days = 10;
metrics = sometrics = ptmetrics = zeros(dim, dim, length(days));
page_screen_output(0);
for n = 1:length(days);
  printf("%i ", length(days) - n);

  ## set time span
  mp.Tspan = LAL_DAYSID_SI * days(n);

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

  ## calculate phase metric through SpinOrbit functions
  # somtype = SOMT_SPIN + SOMT_ORBIT + SOMT_PTOLEMAIC;
  # somret = CreateSpinOrbitMetric(somtype, mp.Tspan, mp.signalParams.Doppler.refTime, edat, mp.detInfo, fmax, 2);
  # sometrics(:,:,n) = SpinOrbitGetMetric(somret).data;

  ## calculate phase metric, Ptolemaic approx
  ptmetrics(:,:,n) = PtoleApproxMetric(1:dim, mp.Tspan);
  ii = [1:4, dim:-1:5];
  ptmetrics(:,:,n) = ptmetrics(ii,ii,n);

endfor
printf("\n");
page_screen_output(1);

## cleanup
clear edat mp mret somret;

## remove nearly-zero entries
##metrics(abs(metrics) < 1e-12) = 0;
##sometrics(abs(metrics) < 1e-12) = 0;
##ptmetrics(abs(ptmetrics) < 1e-12) = 0;

## get r.m.s. differences
# ptmetric_errors = squeeze(sqrt(sum(sum(abs(metrics - ptmetrics).^2, 1), 2) / dim^2));
# sometric_errors = squeeze(sqrt(sum(sum(abs(metrics - sometrics).^2, 1), 2) / dim^2));
