close all;

%Rsqr_H = SqrSNRGeometricFactorHist("T", 0.1, "sdelta", 1.02, "alpha", 6.12, "detectors", {"LHO"});
%Rsqr_H = SqrSNRGeometricFactorHist("T", 0.1, "sdelta", 0.5, "alpha", 0, "psi", 0);


R2 = linspace(5/16, 5/2, 300);

p = sqrt(2) ./ sqrt( (5 + 2.*R2) .* (-15 + 2.*sqrt(50 + 20.*R2) ) );

figure;
hold off
plotHist(Rsqr_H, "k")
hold on
axis manual
plot(R2, p)
