RcRc = DetectorRespKron(inf, [], [], "LHO", "LLO", "VIRGO");

apxsqr = SignalNormAmpSqr("nonax", [-1 1]);

Fpxsqr = BeamPatternSqr(RcRc, [0 2*pi], [-1 1], [-1 1]*pi/4);

Rsqr = SignalToNoiseRsqr(apxsqr, Fpxsqr);

dof = 4; #logspace(log10(2), log10(100), 25);
xa  = linspace(10, 80, 35);
[gdof, gxa] = ndgrid(dof, xa);

tic
Q = SensitivityQ(0.1, gdof, gxa, Rsqr);
toc
