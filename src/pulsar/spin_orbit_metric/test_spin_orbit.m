lal;
lalpulsar;
lal.lalcvar.lalDebugLevel = 1;

try
  edat = InitBarycenter("earth05-09.dat", "sun05-09.dat");
catch
  error("%s: Could not load ephemerides", funcName);
end_try_catch

ptole = false;
nspin = 1;

dets = new_MultiDetectorInfo;
dets.sites{1} = lalcvar.lalCachedDetectors{1+lal.LAL_LHO_4K_DETECTOR};
dets.length = 1;
dets.detWeights(1:dets.length) = 1;

ref_time = LIGOTimeGPS(800000000);

Tspan = LAL_DAYSID_SI * 10;
fmax = 100;

g_ss = SuperskyMetric(ptole, Tspan, ref_time, edat, dets, fmax, nspin);

N = 10;

[s1, s2] = RandomSuperskyMismatch(0.2*ones(N,1), g_ss, [100 0]);
ds = s1 - s2;

sro_type = SOMT_SPIN + SOMT_REDUCED + SOMT_ORBIT;
if ptole
  sro_type += SOMT_PTOLEMAIC;
endif
sro_ret = CreateSpinOrbitMetric(sro_type, Tspan, ref_time, edat, dets, fmax, nspin);
g_sro = SpinOrbitGetMetric(sro_ret).data(:,:);

dso = zeros(size(g_sro, 1), N);

f1 = f2 = zeros(PULSAR_MAX_SPINS, 1);

for i = 1:N

  n1 = s1(1:3, i);
  n2 = s2(1:3, i);
  f1(1:nspin+1) = s1(4:end, i);
  f2(1:nspin+1) = s2(4:end, i);

  so1 = SpinOrbitMetricCoordFromSupersky(sro_ret, n1, f1, ref_time);
  so2 = SpinOrbitMetricCoordFromSupersky(sro_ret, n2, f2, ref_time);

  dso(:,i) = so1.data - so2.data;

endfor

mu_ss = dot(ds, g_ss * ds);
mu_sro = dot(dso, g_sro * dso);

relerr = abs(mu_ss - mu_sro) ./ mu_ss;

fprintf("relerr: min=%0.3g mean=%0.3g max=%0.3g\n", min(relerr), mean(relerr), max(relerr));

so_type = SOMT_SPIN + SOMT_ORBIT;
if ptole
  so_type += SOMT_PTOLEMAIC;
endif
so_ret = CreateSpinOrbitMetric(so_type, Tspan, ref_time, edat, dets, fmax, 1);
g_so = SpinOrbitGetMetric(so_ret).data(:,:);
g_so
