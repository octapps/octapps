function DebugPrintStackparams ( level, stackparams )
  global debugLevel;
  if ( isempty ( debugLevel ) ) debugLevel = 0; endif

  if ( debugLevel < level )
    return;
  endif
  DAYS = 86400;

  if ( isfield ( stackparams, "L0" ) )
    L0 = stackparams.L0;
  else
    L0 = NA;
  endif
  if ( isfield ( stackparams, "nonlinearMismatch") && stackparams.nonlinearMismatch )
    L0name = "L0NLM";
  else
    L0name = "L0LIN";
  endif

  if ( isfield ( stackparams, "costConstraint" ) )
    dC = stackparams.costConstraint;
  else
    dC = NA;
  endif

  %% ----- backwards-compatibility clause ----------
  if ( isfield ( stackparams, "mc" ) ) mCoh = stackparams.mc; else mCoh = stackparams.mCoh; endif
  if ( isfield ( stackparams, "mf" ) ) mInc = stackparams.mf; else mInc = stackparams.mInc; endif

  %% ----- output this
  fprintf ( stderr, " {Nseg = %6.1f, Tseg = %7.2f d, Tobs = %7.2f d, mCoh = %-7.2g, mInc = %-7.2g} : dCC0=%+6.0e : %s=%+8.2e",
            stackparams.Nseg, stackparams.Tseg/DAYS, stackparams.Nseg * stackparams.Tseg/DAYS, mCoh, mInc, dC, L0name, L0 );
  if ( isfield ( stackparams, "DepthNLM" ) )
    fprintf ( stderr, " ==> DepthNLM = %6.1f", stackparams.DepthNLM );
  endif

  return;
endfunction %% DebugPrintStackparams()
