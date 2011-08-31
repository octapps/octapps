%% Calculates a histogram of the "R^2" component of the
%% optimal signal-to-noise ratio
%% Syntax:
%%   Rsqr = SignalToNoiseRsqr(apxsqr, Fpxsqr, "property", value, ...)
%% where:
%%   Rsqr   = returned histogram of "R^2" component of the optimal SNR
%%
%%   apxsqr = joint histogram of normalised signal amplitudes
%%   Fpxsqr = joint histogram of time-averaged beam patterns
%%
%%   optional allowed property-value pairs are
%%   "mismatchHist" = mismatch histogram [defaults to mismatch=0]
%%   "err"          = convergence requirement on histogram [default = 1e-2]
%%   "binsize"      = bin-size of resulting histogram [default = 0.01]

function hRsqr = SignalToNoiseRsqr(hapxsqr, hFpxsqr, varargin )

  %% check input
  assert(isHist(hapxsqr) && isHist(hFpxsqr));

  %% parse optional keywords, set defaults if not specified
  dx0 = 0.01;
  err0 = 1e-2;
  hmis0 = newHist(1, 0.0);
  kv = keyWords ( varargin, "err", err0, "binsize", dx0, "mismatchHist", hmis0 );

  if ( !isHist ( kv.mismatchHist ) )
    error ("%s: mismatchHist must be a histogram struct!", funcName );
  endif
  hmis = kv.mismatchHist;
  %% ----------

  hRsqr = newHist;

  %% if both histograms are "constant", return new histogram
  if (isempty(hapxsqr.px) && isempty(hFpxsqr.px) && isempty(hmis.px) )
    hRsqr.xb{1} = hapxsqr.xb{1}*hFpxsqr.xb{1} + hapxsqr.xb{2}*hFpxsqr.xb{2};
    hRsqr.xb{1} *= ( 1 - hmis.xb{1} );	%% multiply by 1-mismatch
  else

    %% otherwise, build up histogram
    N = 20000;	%% number of random draws in each loop-iteration

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
      hRsqr = addDataToHist(hRsqr, Rsqr, kv.binsize);

      %% calculate difference between old and new histograms
      err = histMetric(hRsqr, oldhRsqr);

      %% continue until error is small enough
      %% (exit after 1 iteration if all parameters are constant)
    until err < kv.err

    %% output histogram
    hRsqr = normaliseHist(hRsqr);

  endif

endfunction
