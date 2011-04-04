%% Calculates a histogram of the "R^2" component of the
%% optimal signal-to-noise ratio
%% Syntax:
%%   Rsqr = SignalToNoiseRsqr(apxsqr, Fpxsqr)
%% where:
%%   apxsqr = joint histogram of normalised signal amplitudes
%%   Fpxsqr = joint histogram of time-averaged beam patterns
%%   mis    = histogram of mismatches
%%   Rsqr   = histogram of "R^2" component of the optimal SNR
function hRsqr = SignalToNoiseRsqr(hapxsqr, hFpxsqr, hmis )

  %% check input
  assert(isHist(hapxsqr) && isHist(hFpxsqr));

  if ( !exist("hmis") )
    hmis = newHist(1);
    hmis.xb{1} = 0;
  endif
  assert ( isHist(hmis) );

  hRsqr = newHist;

  %% if both histograms are "constant", return new histogram
  if (isempty(hapxsqr.px) && isempty(hFpxsqr.px) && isempty(hmis.px) )
    hRsqr.xb{1} = hapxsqr.xb{1}*hFpxsqr.xb{1} + hapxsqr.xb{2}*hFpxsqr.xb{2};
    hRsqr.xb{1} *= ( 1 - hmis.xb{1} );	%% multiply by 1-mismatch
  else

    %% otherwise, build up histogram
    N = 20000;
    dx = 0.01;
    hRsqr = newHist;
    apxsqrwksp = Fpxsqrwksp = miswksp = [];
    do

      %% generate values of ap, ax, Fp, and Fx
      [apxsqr, apxsqrwksp] = drawFromHist(hapxsqr, N, apxsqrwksp);
      [Fpxsqr, Fpxsqrwksp] = drawFromHist(hFpxsqr, N, Fpxsqrwksp);
      [mis, miswksp]       = drawFromHist(hmis,    N, miswksp);

      %% calculate R^2 = (1 - mis) * ( ap^2*Fp^2 + ax^2*Fx^2 )
      Rsqr = ( 1 - mis ) .* sum(apxsqr.*Fpxsqr, 2);

      %% add new values to histogram
      oldhRsqr = hRsqr;
      hRsqr = addDataToHist(hRsqr, Rsqr, dx);

      %% calculate difference between old and new histograms
      err = histMetric(hRsqr, oldhRsqr);

      %% continue until error is small enough
      %% (exit after 1 iteration if all parameters are constant)
    until err < 1e-2

    %% output histogram
    hRsqr = normaliseHist(hRsqr);

  endif

endfunction
