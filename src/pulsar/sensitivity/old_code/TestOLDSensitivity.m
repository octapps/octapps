clear all;

gsl_qrng;

RcRc = DetectorRespKron(inf, [], [], "LHO", "LLO");
apxsqr = SignalNormAmpSqr("nonax", [-1 1]);
Fpxsqr = BeamPatternSqr(RcRc, [0 2*pi], [-1 1], [-pi/4 pi/4]);
Rsqr = SignalToNoiseRsqr(apxsqr, Fpxsqr);

pd = 0.10;
k = 4;

N = 1
sa = 13.3*[1 2 3 4]
Q = SensitivityQ(pd, N, k, sa, Rsqr)
Q0 = SensitivityQ(pd, N, k, sa, Rsqr, "mR^2")
Q ./ Q0

N = 100
sa = 400*[1 1.5 2 2.5]
Q = SensitivityQ(pd, N, k, sa, Rsqr)
Q0 = SensitivityQ(pd, N, k, sa, Rsqr, "mR^2")
Q ./ Q0
