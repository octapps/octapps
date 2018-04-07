## Copyright (C) 2015 Reinhard Prix
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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Helper function for OptimalSolution4StackSlide_v2()

function funs = OptimalSolution4StackSlide_v2_helpers ( costFuns, constraints, pFA = 1e-10, pFD = 0.1, nonlinearMismatch = false, sensApprox = [] )

  funs = struct();
  funs.par.small_m = 1e-2;
  funs.par.pFA = pFA;
  funs.par.pFD = pFD;
  funs.par.nonlinearMismatch = nonlinearMismatch;
  funs.par.grid_interpolation = costFuns.grid_interpolation;
  funs.par.sensApprox = sensApprox;
  funs.constraints = constraints;

  funs.costFuns  = costFuns;
  funs.w         = @(sp) ifelse ( isfield(sp,"w") || (sp.w = SensitivityScalingDeviationN ( funs.par.pFA, funs.par.pFD, max([1,sp.Nseg]), funs.par.sensApprox)), sp.w, "error" );

  funs.misAvgNLM = @(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) EmpiricalFstatMismatch ( Tseg, Tobs, xiCoh * mCoh, xiInc * mInc );
  funs.misAvgLIN = @(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) xiCoh * mCoh + xiInc * mInc;
  if ( nonlinearMismatch )
    funs.misAvg  = funs.misAvgNLM;
  else
    funs.misAvg  = funs.misAvgLIN;
  endif
  funs.zCoh      = @(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) ( funs.misAvg (Tseg, Tobs, mCoh + funs.par.small_m, xiCoh, mInc, xiInc ) - funs.misAvg (Tseg, Tobs, mCoh, xiCoh, mInc, xiInc ) ) / funs.par.small_m;
  funs.zInc      = @(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) ( funs.misAvg (Tseg, Tobs, mCoh, xiCoh, mInc + funs.par.small_m, xiInc ) - funs.misAvg (Tseg, Tobs, mCoh, xiCoh, mInc, xiInc ) ) / funs.par.small_m;

  if ( ! funs.par.grid_interpolation )
    ## ---------- NON-Interpolating (NONI) case ----------
    funs.cost                   = @(sp) costFuns.f( sp.Nseg, sp.Tseg, [], sp.mInc );
    solvers.unconstrained       = @(stackparams,funs)             NONI_unconstrained ( stackparams, funs );
    solvers.constrainedTobs     = @(stackparams,funs,Tobs0)       NONI_constrainedTobs ( stackparams, funs, Tobs0 );
    solvers.constrainedTseg     = @(stackparams,funs,Tseg0)       NONI_constrainedTseg ( stackparams, funs, Tseg0 );
    solvers.constrainedTobsTseg = @(stackparams,funs,Tobs0,Tseg0) NONI_constrainedTobsTseg ( stackparams, funs, Tobs0, Tseg0 );
  else
    ## ---------- Interpolating (INT) case ----------
    funs.cost                   = @(sp) costFuns.f( sp.Nseg, sp.Tseg, sp.mCoh, sp.mInc );
    solvers.unconstrained       = @(stackparams,funs)             INT_unconstrained ( stackparams, funs );
    solvers.constrainedTobs     = @(stackparams,funs,Tobs0)       INT_constrainedTobs ( stackparams, funs, Tobs0 );
    solvers.constrainedTseg     = @(stackparams,funs,Tseg0)       INT_constrainedTseg ( stackparams, funs, Tseg0 );
    solvers.constrainedTobsTseg = @(stackparams,funs,Tobs0,Tseg0) INT_constrainedTobsTseg ( stackparams, funs, Tobs0, Tseg0 );
  endif
  funs.solvers = solvers;

  funs.L0             = @(sp) ( 1 - sp.misAvg ) .* sp.Tseg .* sp.Nseg.^(1 - 1./(2*funs.w(sp)));
  funs.costConstraint = @(sp) ( (sp.cost - funs.constraints.cost0)/funs.constraints.cost0);     ## Note: keep sign, allows accepting cost < cost0 solutions ...

  funs.cratio = @(mCoh,mInc,sp) ...
                 (funs.zCoh(sp.Tseg,sp.Nseg*sp.Tseg,mCoh,sp.coefCoh.xi,mInc,sp.coefInc.xi) .* mCoh ./ sp.coefCoh.nDim) ...
                ./ (funs.zInc(sp.Tseg,sp.Nseg*sp.Tseg,mCoh,sp.coefCoh.xi,mInc,sp.coefInc.xi) .* mInc ./ sp.coefInc.nDim );

  funs.complete_stackparams = @(sp,funs) complete_stackparams ( sp, funs );

  funs.local_cost_coefs = @(costFuns,sp) LocalCostCoefficients_v2 ( costFuns, round(sp.Nseg), sp.Tseg, sp.mCoh, sp.mInc );

  return;

endfunction ## OptimalSolution4StackSlide_v2_helpers()

## ==================== NON-Interpolating solvers ====================

function sol = NONI_unconstrained ( stackparams, funs )
  global debugLevel; global powerEps;
  sol = [];
  ## ----- local shortcuts ----------
  coef = stackparams.coefInc;
  delta = coef.delta; eta = coef.eta; eps = coef.eps; a = coef.a; n = coef.nDim; k = coef.kappa; xi = coef.xi;
  w = stackparams.w;
  cost0 = funs.constraints.cost0;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  ## check if an unconstrained solution is even deemed possible at all: did we hit one of the 'hard' boundaries?
  if ( isfield(stackparams, "hitNsegMinSemi") && stackparams.hitNsegMinSemi && (a < -powerEps) )
    DebugPrintf ( 2, "\n%s: Hit NsegMinSemi at a = %g < 0 ==> computing coherent unconstrained solution!\n", funcName, a );
    sol = COH_unconstrained ( stackparams, funs );
    return;
  endif
  if ( isfield(stackparams, "hitTsegMin") && stackparams.hitTsegMin && (a > powerEps) )
    DebugPrintf ( 2, "\n%s: Hit TsegMin at a = %g > 0 ==> giving up!\n", funcName, a );
    return;
  endif
  if ( isfield(stackparams, "hitTobsMax") && stackparams.hitTobsMax )
    if ( (a > powerEps) && (eps > powerEps) )
      DebugPrintf ( 2, "\n%s: Hit TobsMax at (a = %g > 0 && eps = %g > 0) ==> giving up!\n", funcName, a, eps );
      return;
    elseif ( (a < -powerEps) && (eps < -powerEps) )
      DebugPrintf ( 2, "\n%s: Hit TobsMax at (a = %g < 0 && eps = %g < 0) ==> giving up!\n", funcName, a, eps );
      return;
    endif
  endif

  ## ==================== Step 1: solve for optimal mismatch ====================

  ## ---------- Step 1a: check denominator zero and truncate range if required
  denom = @(logm) ( 1 - funs.misAvg ( Tseg, Tobs, 0, 0, exp(logm), xi ) );
  logmRange = log([1e-3, 1e3]);
  ## first check if denominator has a zero in this range
  if ( denom(logmRange(1)) * denom(logmRange(2)) < 0 )
    ## if yes: find it, and truncate range
    try
      [pole, residual, INFO, OUTPUT] = fzero ( denom, logmRange );
      assert( INFO == 1, ...
              "%s: fzero() failed to find pole of denominator: INFO=%i, residual=%g, iterations=%i, mcOpt=[%g,%g], FCN=[%g,%g]\n",
              funcName, INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    catch err
      DebugPrintf ( 3, "%s: 1st fzero() clause failed: trying to find mismatch range \n", funcName );
      if ( debugLevel >= 3 ) err, endif
      return;
    end_try_catch
    logmRange(2) = 0.95 * pole; ## stay below from pole
  endif ## if denominator has zero

  lhs = @(logm) funs.zInc ( Tseg, Tobs, 0, 0, exp(logm), xi ) .* exp(logm) ./ denom(logm);

  ## ---------- Step 1b: solve for mInc using Eqs. obtained from (d_m L=0 and d_N L=0) and (d_m L=0 and d_Tseg L=0) *averaged* (agree when a=0)
  rhs_Nseg  = (n / (2 * eta)) * ( 1 - 1/(2*w) );
  rhs_Tseg  = n / (2 * delta );
  rhs = 0.5 * ( rhs_Nseg + rhs_Tseg );
  FCN = @(logm) lhs(logm) - rhs;
  try
    assert ( FCN(logmRange(1)) * FCN(logmRange(2)) < 0, "%s: logmRange [%g, %g] does not bracket mismatch solution for rhs = %g\n", funcName, logmRange(1),logmRange(2), rhs );
    [log_mOpt, residual, INFO, OUTPUT] = fzero ( FCN, logmRange );
    assert( INFO == 1,
            "%s: fzero() failed to find mismatch solution for rhs = %g: INFO=%i, residual=%g, iterations=%i, log(mcOpt)=[%g,%g], FCN=[%g,%g]\n",
            funcName, rhs, INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    mOpt = exp ( log_mOpt );
  catch err
    DebugPrintf ( 3, "%s: 2nd fzero() clause failed: trying to solve for optimal mismatch\n", funcName );
    if ( debugLevel >= 3) err, endif
    return;
  end_try_catch

  ## if |a| ~ 0, we're done here
  if ( abs(a) <= powerEps )
    DebugPrintf ( 3, "%s: |%a| ~ 0 ==> {Nseg = %g,Tseg = %g d} assumed optimal\n", funcName, a, stackparams.Nseg, stackparams.Tseg );
    sol = struct ( "Nseg", stackparams.Nseg, "Tseg", stackparams.Tseg, "mCoh", mOpt, "mInc", mOpt );
    return;
  endif

  ## ========== Step 2: devise a step in {Tseg,Nseg} in the 'right direction', proportional to |a| to ensure convergence ==========
  ## a > 0: decrease Tseg, if a < 0: increase Tseg, 'proportional' to 'a' for convergence
  ## use '-atan(a)' in [-pi/2,pi/2] in order to control the stepsize-scale
  TsegNew = stackparams.Tseg * ( 1 - atan ( a ) / pi );
  ## compute C0-consistent Nseg from this:
  logN = 1/eta * ( log(cost0/k) + n/2 * log(mOpt) - delta * log(TsegNew) );
  NsegNew = exp ( logN );

  sol = struct ( "Nseg", NsegNew, "Tseg", TsegNew, "mCoh", mOpt, "mInc", mOpt );

  return;

endfunction ## NONI_unconstrained()

function sol = NONI_constrainedTobs ( stackparams, funs, Tobs0 )
  global powerEps; global debugLevel; global DAYS;
  sol = [];

  ## ----- local shortcuts ----------
  coef = stackparams.coefInc;
  w = stackparams.w;
  delta = coef.delta; eta = coef.eta; eps = coef.eps; a = coef.a; n = coef.nDim; k = coef.kappa; xi = coef.xi;
  cost0 = funs.constraints.cost0;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  if ( eps < powerEps )
    ## ----- "eps < 0": solve for Tobs-constrained *coherent* solution
    DebugPrintf ( 2, "\n%s: eps = %g <~ 0: calling COH_constrainedTobs()\n", funcName, eps );
    sol = COH_constrainedTobs ( stackparams, funs, Tobs0 );
    return;
  endif

  ## ----- eps > 0: solve for Tobs-constrained *semi-coherent* solution
  rhs = n / (4 * w * eps );
  denom = @(logm) ( 1 - funs.misAvg ( Tseg, Tobs, 0, 0, exp(logm), xi ) );
  FCN   = @(logm) funs.zInc ( Tseg, Tobs, 0, 0, exp(logm), xi ) .* exp(logm) ./ denom(logm) - rhs;
  logmRange = log([1e-3, 1e3]);
  ## first check if denominator has a zero in this range
  if ( denom(logmRange(1)) * denom(logmRange(2)) < 0 )
    ## if yes: find it, and truncate range
    try
      [pole, residual, INFO, OUTPUT] = fzero ( denom, logmRange );
      assert( INFO == 1, ...
              "fzero() failed to find pole of denominator: INFO=%i, residual=%g, iterations=%i, mcOpt=[%g,%g], FCN=[%g,%g]\n",
              INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    catch err
      DebugPrintf ( 3, "%s: 1st fzero() clause failed: trying to find mismatch range \n", funcName );
      if ( debugLevel >= 3 ) err, endif
      return;
    end_try_catch
    logmRange(2) = 0.95 * pole; ## stay below from pole
  endif
  try
    assert ( FCN(logmRange(1)) * FCN(logmRange(2)) < 0, "logmRange [%g, %g] does not bracket coherent mismatch solution for rhs = %g\n", logmRange(1),logmRange(2), rhs);
    [logOpt, residual, INFO, OUTPUT] = fzero ( FCN, logmRange );
    assert( INFO == 1,
            "fzero() failed to find mismatch solution for rhs = %g: INFO=%i, residual=%g, iterations=%i, log(mcOpt)=[%g,%g], FCN=[%g,%g]\n",
            rhs, INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    mOpt = exp ( logOpt );
  catch err
    DebugPrintf ( 3, "%s: 2nd fzero() clause failed: trying to solve for optimal mismatch\n", funcName );
    if ( debugLevel >= 3) err, endif
    return;
  end_try_catch

  logNopt = -1/eps * ( log(cost0/k) + n/2 * log(mOpt) - delta * log(Tobs0) );
  NsegOpt = exp ( logNopt );
  TsegOpt = Tobs0 / NsegOpt;

  if ( (TsegOpt < funs.constraints.TsegMin) && isfield(stackparams, "hitTsegMin") && stackparams.hitTsegMin )   ## keeps pushing down->give up
    DebugPrintf ( 2, "\n%s: TsegOpt = %g d: keeps pushing below TsegMin = %g d ==> giving up!\n", funcName, TsegOpt/DAYS, funs.constraints.TsegMin/DAYS );
    return;
  endif
  if ( (TsegOpt > funs.constraints.TsegMax) && isfield(stackparams, "hitTsegMax") && stackparams.hitTsegMax ) ## keeps pushing up->give up
    DebugPrintf ( 2, "\n%s: TsegOpt = %g d: keeps pushing above TsegMax = %g d ==> giving up!\n", funcName, TsegOpt/DAYS, funs.constraints.TsegMax/DAYS );
    return;
  endif

  sol = struct ( "Nseg", NsegOpt, "Tseg", TsegOpt, "mCoh", mOpt, "mInc", mOpt );

  return;
endfunction ## NONI_constrainedTobs()

function sol = NONI_constrainedTseg ( stackparams, funs, Tseg0 )
  global debugLevel; global DAYS;
  sol = [];

  ## ----- local shortcuts ----------
  cost0 = funs.constraints.cost0;
  coef = stackparams.coefInc;
  delta = coef.delta; eta = coef.eta; n = coef.nDim; k = coef.kappa; xi = coef.xi;
  w = stackparams.w = funs.w ( stackparams );
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  ## ----- solve for optimal mismatch ----------
  rhs = (n / (2 * eta )) * ( 1 - 1/(2*w) );
  denom = @(logm) ( 1 - funs.misAvg ( Tseg, Tobs, 0, 0, exp(logm), xi ) );
  FCN   = @(logm) funs.zInc ( Tseg, Tobs, 0, 0, exp(logm), xi ) .* exp(logm) ./ denom(logm) - rhs;
  logmRange = log([1e-3, 1e3]);
  ## first check if denominator has a zero in this range
  if ( denom(logmRange(1)) * denom(logmRange(2)) < 0 )
    ## if yes: find it, and truncate range
    try
      [pole, residual, INFO, OUTPUT] = fzero ( denom, logmRange );
      assert( INFO == 1, ...
              "fzero() failed to find pole of denominator: INFO=%i, residual=%g, iterations=%i, mcOpt=[%g,%g], FCN=[%g,%g]\n",
              INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    catch err
      DebugPrintf ( 3, "%s: 1st fzero() clause failed: trying to find mismatch range\n", funcName );
      if ( debugLevel >= 3 ) err, endif
      return;
    end_try_catch
    logmRange(2) = 0.95 * pole; ## stay below from pole
  endif
  try
    assert ( FCN(logmRange(1)) * FCN(logmRange(2)) < 0, "logmRange [%g, %g] does not bracket mismatch solution for rhs = %g\n", logmRange(1),logmRange(2), rhs);
    [logOpt, residual, INFO, OUTPUT] = fzero ( FCN, logmRange );
    assert( INFO == 1,
            "fzero() failed to find mismatch solution for rhs = %g: INFO=%i, residual=%g, iterations=%i, log(mcOpt)=[%g,%g], FCN=[%g,%g]\n",
            rhs, INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    mOpt = exp ( logOpt );
  catch err
    DebugPrintf ( 3, "%s: 2nd fzero() clause failed: trying to find optimal mismatch\n", funcName );
    if ( debugLevel >= 3) err, endif
    return;
  end_try_catch

  logNopt = 1/eta * ( log(cost0/k) + n/2 * log(mOpt) - delta * log(Tseg0) );
  NsegOpt = exp ( logNopt );

  if ( (NsegOpt < funs.constraints.NsegMinSemi) && isfield ( stackparams, "hitNsegMinSemi" ) && stackparams.hitNsegMinSemi )
    DebugPrintf ( 2, "\n%s: NsegOpt = %g: keeps pushing below NsegMinSemi = %g: calling COH_constrainedTobs()\n", funcName, NsegOpt, funs.constraints.NsegMinSemi );
    sol = COH_constrainedTobs ( stackparams, funs, Tseg0 );
    return;
  endif

  TobsOpt = NsegOpt * Tseg0;
  if ( (TobsOpt > funs.constraints.TobsMax) && isfield ( stackparams, "hitTobsMax" ) && stackparams.hitTobsMax );
    DebugPrintf ( 2, "\n%s: TobsOpt = %g d: keeps pushing above TsegMax = %g d ==> giving up\n", funcName, TobsOpt/DAYS, funs.constraints.TobsMax/DAYS );
    return;
  endif

  sol = struct ( "Nseg", NsegOpt, "Tseg", Tseg0, "mCoh", mOpt, "mInc", mOpt );

  return;
endfunction ## NONI_constrainedTseg()

function sol = NONI_constrainedTobsTseg ( stackparams, funs, Tobs0, Tseg0 )
  global debugLevel;

  assert ( Tseg0 <= Tobs0 );
  sol = [];

  cost0 = funs.constraints.cost0;
  coef = stackparams.coefInc;
  delta = coef.delta; eta = coef.eta; n = coef.nDim; k = coef.kappa;

  Nseg0 = Tobs0 / Tseg0;

  logm = -(2/n) * ( log(cost0/k) - eta * log(Nseg0) - delta * log(Tseg0) );
  mOpt = exp ( logm );

  sol = struct ( "Nseg", Nseg0, "Tseg", Tseg0, "mCoh", mOpt, "mInc", mOpt );

  return;
endfunction ## NONI_constrainedTobsTseg()

## ==================== Interpolating solvers ====================
function sol = INT_unconstrained ( stackparams, funs )
  global debugLevel; global powerEps;

  sol = [];
  ## ----- local shortcuts ----------
  coefCoh = stackparams.coefCoh;
  coefInc = stackparams.coefInc;
  deltaCoh = coefCoh.delta; etaCoh = coefCoh.eta; epsCoh = coefCoh.eps; aCoh = coefCoh.a; nCoh = coefCoh.nDim; kCoh = coefCoh.kappa; xiCoh = coefCoh.xi;
  deltaInc = coefInc.delta; etaInc = coefInc.eta; epsInc = coefInc.eps; aInc = coefInc.a; nInc = coefInc.nDim; kInc = coefInc.kappa; xiInc = coefInc.xi;
  cost0 = funs.constraints.cost0;
  D = deltaCoh * etaInc - deltaInc * etaCoh;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  if ( aCoh * aInc < 0 )
    assert ( abs(D) > powerEps, "D = 0 but (aCoh * aInc < 0) is contradictory!\n");
    ## ----- unconstrained semi-coherent solution exists
    crOpt = - aInc / aCoh;
    rCoh = (nCoh/2) * ( crOpt / ( crOpt * deltaCoh + deltaInc ) );
    rInc = (nInc/2) * ( 1     / ( crOpt * deltaCoh + deltaInc ) );
    denom = @(mCoh,mInc) ( 1 - funs.misAvg(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) );
    FCN = @(v) [ funs.zCoh(Tseg,Tobs,exp(v(1)),xiCoh,exp(v(2)),xiInc) * exp(v(1)) / denom(exp(v(1)),exp(v(2))) - rCoh; ...
                 funs.zInc(Tseg,Tobs,exp(v(1)),xiCoh,exp(v(2)),xiInc) * exp(v(2)) / denom(exp(v(1)),exp(v(2))) - rInc ];
    xi0 = 0.5;
    solLin = log ( [ rCoh / ( 1 + rCoh + rInc ) / xi0, rInc / ( 1 + rCoh + rInc ) / xi0 ] );
    try
      DebugPrintf ( 4, "\n");
      opts = optimset ( "Display", "iter", "OutputFcn", @DebugPrintFsolve ); ## , "AutoScaling", "on" );
      [X, FVEC, INFO, OUTPUT, FJAC] = fsolve ( FCN, solLin, opts );
      assert ( INFO == 1, "%s: fsolve() failed to find {mCoh,mInc}(cratio). INFO = %d\n", funcName(), INFO );
      mCohOpt = exp(X(1));
      mIncOpt = exp(X(2));
      assert ( (mCohOpt >= 0) && (mIncOpt >= 0), "%s: fsolve() converged, but invalid negative solution {mCoh = %g, mInc = %g} < 0\n", funcName(), mCohOpt, mIncOpt );
    catch err
      if ( debugLevel >= 3) err, endif
      return;
    end_try_catch
    CostCoh0 = cost0 / ( 1 + 1/crOpt );
    CostInc0 = cost0 / ( 1 + crOpt );
    logTseg = (1/D) * ( + etaInc * log(CostCoh0/kCoh) + etaInc * nCoh/2 * log(mCohOpt) ...
                        - etaCoh * log(CostInc0/kInc) - etaCoh * nInc/2 * log(mIncOpt) );
    TsegOpt = exp(logTseg);
    logNseg = (1/D) * ( + deltaCoh * log(CostInc0/kInc) + deltaCoh * nInc/2 * log(mIncOpt) ...
                        - deltaInc * log(CostCoh0/kCoh) - deltaInc * nCoh/2 * log(mCohOpt) );
    NsegOpt = exp(logNseg);

    sol = struct ( "Nseg", NsegOpt, "Tseg", TsegOpt, "mCoh", mCohOpt, "mInc", mIncOpt );

  elseif ( (aCoh < -powerEps) && (aInc < -powerEps) )
    ## ----- means {decrease N, increase Tseg, decrease Tobs} --> solve for unconstrained coherent solution
    DebugPrintStackparams ( 3, stackparams ); DebugPrintf ( 3, "\n");
    DebugPrintf ( 2, "\n%s: aCoh = %g <~ 0 && aInc = %g <~0: calling COH_unconstrained()\n", funcName, aCoh, aInc );
    sol = COH_unconstrained ( stackparams, funs );

  elseif ( (aCoh > powerEps) && (aInc > powerEps) )
    ## ----- means {increase T, decrease Tseg, increase N} --> need at least TobsMax constraint
    DebugPrintStackparams ( 3, stackparams ); DebugPrintf ( 3, "\n");
    DebugPrintf ( 2, "\n%s: aCoh = %g > 0 && aInc = %g > 0: no unconstrained solution possible.", funcName, aCoh, aInc );
    sol = [];

  else
    DebugPrintf ( 2, "\n%s: aCoh = %g ~0 && aInc = %g ~0 means we're at optimal solution already!\n", funcName, aCoh, aInc );
    sol = stackparams;
  endif

  return;
endfunction ## INT_unconstrained()

function sol = INT_constrainedTobs ( stackparams, funs, Tobs0 )
  global powerEps; global debugLevel; global DAYS;
  sol = [];

  ## ----- local shortcuts ----------
  coefCoh = stackparams.coefCoh;
  coefInc = stackparams.coefInc;
  w = stackparams.w;
  deltaCoh = coefCoh.delta; etaCoh = coefCoh.eta; epsCoh = coefCoh.eps; aCoh = coefCoh.a; nCoh = coefCoh.nDim; kCoh = coefCoh.kappa; xiCoh = coefCoh.xi;
  deltaInc = coefInc.delta; etaInc = coefInc.eta; epsInc = coefInc.eps; aInc = coefInc.a; nInc = coefInc.nDim; kInc = coefInc.kappa; xiInc = coefInc.xi;
  D = deltaCoh * etaInc - deltaInc * etaCoh;
  cost0 = funs.constraints.cost0;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  if ( abs(epsCoh) < powerEps && abs(epsInc) < powerEps )
    ## ----- solve for Tobs-constrained *coherent* solution
    DebugPrintStackparams ( 3, stackparams ); DebugPrintf ( 3, "\n");
    DebugPrintf ( 2, "\n%s: epsCoh = %g <~ 0 && epsInc = %g <~0: calling COH_constrainedTobs().\n", funcName, epsCoh, epsInc );
    sol = COH_constrainedTobs ( stackparams, funs, Tobs0 );
    return;

  else
    ## ----- solve for Tobs-constrained *semi-coherent* solution
    cr       = @(mCoh,mInc) funs.cratio ( mCoh, mInc, stackparams );
    eq_Tobs  = @(mCoh,mInc) ...
               - D * log(Tobs0) ...
               + epsCoh * log ( cost0/kInc ) ...
               - epsInc * log ( cost0/kCoh ) ...
               + epsInc * log ( mCoh^(-nCoh/2) * ( 1 + 1/cr(mCoh,mInc) ) ) ...
               - epsCoh * log ( mInc^(-nInc/2) * ( 1 + cr(mCoh,mInc) ) );
    eq_Nseg0 = @(mCoh,mInc) ...
               - (1 - funs.misAvg(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) ) / (4 * w ) ...
               + epsCoh * mCoh * funs.zCoh(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) / nCoh ...
               + epsInc * mInc * funs.zInc(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) / nInc;
    FCN = @(v) [ eq_Tobs(exp(v(1)),exp(v(2))); eq_Nseg0(exp(v(1)),exp(v(2))) ];
    guess = log ( [ 0.5, 0.5 ] );
    try
      DebugPrintf ( 4, "\n");
      opts = optimset ( "Display", "iter", "OutputFcn", @DebugPrintFsolve ); ## , "AutoScaling", "on" );
      [X, FVEC, INFO, OUTPUT, FJAC] = fsolve ( FCN, guess, opts );
      assert ( INFO == 1, "%s: fsolve() failed to find {mCoh,mInc} at fixed Tobs0. INFO = %d\n", funcName(), INFO );
      mCohOpt = exp(X(1));
      mIncOpt = exp(X(2));
      assert ( (mCohOpt >= 0) && (mIncOpt >= 0), "%s: fsolve() for fixed Tobs0 converged, but invalid negative solution {mCoh = %g, mInc = %g} < 0\n", funcName(), mCohOpt, mIncOpt );
    catch err
      if ( debugLevel >= 3 ) err, endif
      return;
    end_try_catch

    crOpt    = cr ( mCohOpt, mIncOpt );
    CostCoh0 = cost0 / ( 1 + 1/crOpt );
    CostInc0 = cost0 / ( 1 + crOpt );
    if ( abs(epsCoh) >= powerEps )
      logN = -(1/epsCoh) * ( log(CostCoh0/kCoh) + nCoh/2 * log(mCohOpt) - deltaCoh * log(Tobs0) );
    else
      logN = -(1/epsInc) * ( log(CostInc0/kInc) + nInc/2 * log(mIncOpt) - deltaInc * log(Tobs0) );
    endif
    NsegOpt = exp ( logN );
    TsegOpt = Tobs0 / NsegOpt;

    if ( (TsegOpt < funs.constraints.TsegMin) && isfield(stackparams, "hitTsegMin") && stackparams.hitTsegMin ) ## keeps pushing down->give up
      DebugPrintf ( 2, "\n%s: TsegOpt = %g d: keeps pushing below TsegMin = %g d ==> giving up!\n", funcName, TsegOpt/DAYS, funs.constraints.TsegMin/DAYS );
      return;
    endif
    if ( (TsegOpt > funs.constraints.TsegMax) && isfield(stackparams, "hitTsegMax") && stackparams.hitTsegMax ) ## keeps pushing up->give up
      DebugPrintf ( 2, "\n%s: TsegOpt = %g d: keeps pushing above TsegMax = %g ==> giving up!\n", funcName, TsegOpt/DAYS, funs.constraints.TsegMax/DAYS );
      return;
    endif

    sol = struct ( "Nseg", NsegOpt, "Tseg", TsegOpt, "mCoh", mCohOpt, "mInc", mIncOpt );
  endif

  return;
endfunction ## INT_constrainedTobs()

function sol = INT_constrainedTseg ( stackparams, funs, Tseg0 )
  global debugLevel; global DAYS;

  sol = [];
  ## ----- local shortcuts ----------
  coefCoh = stackparams.coefCoh;
  coefInc = stackparams.coefInc;
  w = stackparams.w;
  deltaCoh = coefCoh.delta; etaCoh = coefCoh.eta; epsCoh = coefCoh.eps; aCoh = coefCoh.a; nCoh = coefCoh.nDim; kCoh = coefCoh.kappa; xiCoh = coefCoh.xi;
  deltaInc = coefInc.delta; etaInc = coefInc.eta; epsInc = coefInc.eps; aInc = coefInc.a; nInc = coefInc.nDim; kInc = coefInc.kappa; xiInc = coefInc.xi;
  D = deltaCoh * etaInc - deltaInc * etaCoh;
  cost0 = funs.constraints.cost0;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------
  cr       = @(mCoh,mInc) funs.cratio ( mCoh, mInc, stackparams );
  eq_Tseg  = @(mCoh,mInc) ...
             - D * log(Tseg0) ...
             + etaInc * log ( cost0/kCoh ) ...
             - etaCoh * log ( cost0/kInc ) ...
             + etaCoh * log ( mInc^(-nInc/2) * ( 1 + cr(mCoh,mInc) ) ) ...
             - etaInc * log ( mCoh^(-nCoh/2) * ( 1 + 1/cr(mCoh,mInc) ) );
  eq_Nseg1 = @(mCoh,mInc) ...
             - (1/2)*(1 - funs.misAvg(Tseg,Tobs,mCoh,xiCoh,mInc,mInc) ) * (1 - 1/(2*w) ) ...
             + etaCoh * mCoh * funs.zCoh(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) / nCoh ...
             + etaInc * mInc * funs.zInc(Tseg,Tobs,mCoh,xiCoh,mInc,xiInc) / nInc;
  FCN = @(v) [ eq_Tseg(exp(v(1)),exp(v(2))); eq_Nseg1(exp(v(1)),exp(v(2))) ];
  guess = log ( [ 0.5, 0.5 ] );
  try
    DebugPrintf ( 4, "\n");
    opts = optimset ( "Display", "iter", "OutputFcn", @DebugPrintFsolve ); ## , "AutoScaling", "on" );
    [X, FVEC, INFO, OUTPUT, FJAC] = fsolve ( FCN, guess, opts );
    assert ( INFO == 1, "%s: fsolve() failed to find {mCoh,mInc} at fixed Tseg0. INFO = %d\n", funcName(), INFO );
    mCohOpt = exp(X(1));
    mIncOpt = exp(X(2));
    assert ( (mCohOpt >= 0) && (mIncOpt >= 0), "%s: fsolve() for fixed Tseg0 converged, but invalid negative solution {mCoh = %g, mInc = %g} < 0\n", funcName, mCohOpt, mIncOpt );
  catch err
    if ( debugLevel >= 3 ) err, endif
    return;
  end_try_catch

  crOpt   = cr ( mCohOpt, mIncOpt );
  CostCoh0 = cost0 / ( 1 + 1/crOpt );
  CostInc0 = cost0 / ( 1 + crOpt );

  logN = (1/etaCoh) * ( log(CostCoh0/kCoh) + nCoh/2 * log(mCohOpt) - deltaCoh * log(Tseg0) );
  NsegOpt = exp ( logN );
  TsegOpt = Tseg0;

  TobsOpt = NsegOpt * Tseg0;
  if ( (TobsOpt > funs.constraints.TobsMax) && isfield ( stackparams, "hitTobsMax" ) && stackparams.hitTobsMax );
    DebugPrintf ( 2, "\n%s: TobsOpt = %g d: keeps pushing above TsegMax = %g d ==> giving up\n", funcName, TobsOpt/DAYS, funs.constraints.TobsMax/DAYS );
    return;
  endif

  sol = struct ( "Nseg", NsegOpt, "Tseg", TsegOpt, "mCoh", mCohOpt, "mInc", mIncOpt );

  return;
endfunction ## INT_constrainedTseg()

function sol = INT_constrainedTobsTseg ( stackparams, funs, Tobs0, Tseg0 )
  global debugLevel;
  assert ( Tseg0 <= Tobs0 );

  sol = [];
  ## ----- local shortcuts ----------
  coefCoh = stackparams.coefCoh;
  coefInc = stackparams.coefInc;
  w = stackparams.w;
  deltaCoh = coefCoh.delta; etaCoh = coefCoh.eta; epsCoh = coefCoh.eps; aCoh = coefCoh.a; nCoh = coefCoh.nDim; kCoh = coefCoh.kappa; xiCoh = coefCoh.xi;
  deltaInc = coefInc.delta; etaInc = coefInc.eta; epsInc = coefInc.eps; aInc = coefInc.a; nInc = coefInc.nDim; kInc = coefInc.kappa; xiInc = coefInc.xi;
  D = deltaCoh * etaInc - deltaInc * etaCoh;
  cost0 = funs.constraints.cost0;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------
  Nseg0 = Tobs0 / Tseg0;
  cr    = @(mCoh,mInc) funs.cratio ( mCoh, mInc, stackparams );

  eqCoh = @(mCoh,mInc) ...
          - log(cost0/kCoh) + log( 1 + 1/cr(mCoh,mInc) ) ...
          - (nCoh/2) * log(mCoh) ...
          + etaCoh * log(Nseg0) ...
          + deltaCoh * log(Tseg0);
  eqInc = @(mCoh,mInc) ...
          - log(cost0/kInc) + log( 1 + cr(mCoh,mInc) ) ...
          - (nInc/2) * log(mInc) ...
          + etaInc * log(Nseg0) ...
          + deltaInc * log(Tseg0);
  FCN = @(v) [ eqCoh(exp(v(1)),exp(v(2))); eqInc(exp(v(1)),exp(v(2))) ];
  guess = log ( [ 0.5, 0.5 ] );
  try
    DebugPrintf ( 4, "\n");
    opts = optimset ( "Display", "iter", "OutputFcn", @DebugPrintFsolve); ## , "AutoScaling", "on" );
    [X, FVEC, INFO, OUTPUT, FJAC] = fsolve ( FCN, guess, opts );
    assert ( INFO == 1, "%s: fsolve() failed to find {mCoh,mInc} at fixed Tseg0+Tobs0. INFO = %d\n", funcName(), INFO );
    mCohOpt = exp(X(1));
    mIncOpt = exp(X(2));
    assert ( (mCohOpt >= 0) && (mIncOpt >= 0), "%s: fsolve() for fixed Tseg0+Tobs0 converged, but invalid negative solution {mCoh = %g, mInc = %g} < 0\n", funcName(), mCohOpt, mIncOpt );
  catch err
    if ( debugLevel >= 3 ) err, endif
    return;
  end_try_catch

  NsegOpt = Nseg0;
  TsegOpt = Tseg0;
  sol = struct ( "Nseg", NsegOpt, "Tseg", TsegOpt, "mCoh", mCohOpt, "mInc", mIncOpt );

  return;
endfunction ## INT_constrainedTobsTseg()

## ==================== fully COHERENT solvers ====================
function sol = COH_unconstrained ( stackparams, funs )
  global debugLevel;

  sol = [];
  ## ----- local shortcuts ----------
  coef = stackparams.coefCoh;
  deltaCoh = coef.delta; etaCoh = coef.eta; epsCoh = coef.eps; aCoh = coef.a; nCoh = coef.nDim; kCoh = coef.kappa; xiCoh = coef.xi;
  cost0 = funs.constraints.cost0;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  rCoh = (nCoh/2) / deltaCoh;   ## limit of cr->inf
  denom = @(logm) ( 1 - funs.misAvg(Tseg,Tobs,exp(logm), xiCoh, 0, 0 ) );
  FCN = @(logm) funs.zCoh(Tseg,Tobs,exp(logm), xiCoh, 0, 0) .* exp(logm) ./ denom(logm) - rCoh;
  logmRange = log([1e-3, 1e3]);
  ## first check if denominator has a zero in this range
  if ( denom(logmRange(1)) * denom(logmRange(2)) < 0 )
    ## if yes: find it, and truncate range
    try
      [pole, residual, INFO, OUTPUT] = fzero ( denom, logmRange );
      assert( INFO == 1, ...
              "fzero() failed to find pole of denominator: INFO=%i, residual=%g, iterations=%i, mCohOpt=[%g,%g], FCN=[%g,%g]\n",
              INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    catch err
      if ( debugLevel >= 3 ) err, endif
      return;
    end_try_catch
    logmRange(2) = 0.95 * pole; ## stay below from pole
  endif
  try
    assert ( FCN(logmRange(1)) * FCN(logmRange(2)) < 0, "logmRange [%g, %g] does not bracket coherent mismatch solution for rCoh = %g\n", logmRange(1),logmRange(2), rCoh);
    [logOpt, residual, INFO, OUTPUT] = fzero ( FCN, logmRange );
    assert( INFO == 1,
            "fzero() failed to find coherent mismatch solution for rCoh = %g: INFO=%i, residual=%g, iterations=%i, log(mCohOpt)=[%g,%g], FCN=[%g,%g]\n",
            rCoh, INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    mCohOpt = exp ( logOpt );
  catch err
    if ( debugLevel >= 3) err, endif
    return;
  end_try_catch
  logTseg = (1/deltaCoh) * ( log(cost0/kCoh) + nCoh/2 * log(mCohOpt) );
  TsegOpt = exp ( logTseg );

  sol = struct ( "Nseg", 1, "Tseg", TsegOpt, "mCoh", mCohOpt, "mInc", mCohOpt );
  return;

endfunction ## COH_unconstrained()

function sol = COH_constrainedTobs ( stackparams, funs, Tobs0 )
  sol = [];
  ## ----- local shortcuts ----------
  coef = stackparams.coefCoh;
  w = stackparams.w;
  deltaCoh = coef.delta; etaCoh = coef.eta; epsCoh = coef.eps; aCoh = coef.a; nCoh = coef.nDim; kCoh = coef.kappa; xiCoh = coef.xi;
  cost0 = funs.constraints.cost0;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  log_mCoh = 2/nCoh * ( log(kCoh/cost0) + deltaCoh * log(Tobs0) );
  mCohOpt = exp ( log_mCoh );

  sol = struct ( "Nseg", 1, "Tseg", Tobs0, "mCoh", mCohOpt, "mInc", mCohOpt );
  return;

endfunction ## COH_constrainedTobs()

## ----------------------------------------------------------------------------------------------------

function stackparams = complete_stackparams ( stackparams, funs )
  ## stackparams = complete_stackparams ( stackparams, funs )
  ## fill in a number of useful 'derived' stack parameter coefficients
  global debugLevel;

  ## backwards-compatilibity fix: allow 'mc' 'mf' in lieu of 'mCoh', 'mInc'
  if ( !isfield ( stackparams, "mCoh" ) && isfield ( stackparams, "mc" ) )
    warning ("Found no mismatch field 'mCoh' but obsolete 'mc' instead ... using this for now\n");
    stackparams.mCoh = stackparams.mc;
  endif
  if ( !isfield ( stackparams, "mInc" ) && isfield ( stackparams, "mf" ) )
    warning ("Found no mismatch field 'mInc' but obsolete 'mf' instead ... using this for now\n");
    stackparams.mInc = stackparams.mf;
  endif
  ## ----- end compatibility fix ----------

  ## ----- local shortcuts ----------
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  if ( !isfield ( stackparams, "w" ) )
    stackparams.w = funs.w ( stackparams );
  endif

  stackparams.nonlinearMismatch = funs.par.nonlinearMismatch;
  stackparams.Tobs = Tobs;

  if ( !isfield ( stackparams, "coefCoh" ) || !isfield ( stackparams, "coefInc" ) )
    ## ---------- coherent- and incoherent cost coefficients ----------
    try
      [ stackparams.coefCoh, stackparams.coefInc ] = funs.local_cost_coefs ( funs.costFuns, stackparams );
    catch err
      DebugPrintf ( 3, "%s: funs.local_cost_coefs() failed for stackparams = ", funcName );
      if ( debugLevel >= 3 ) stackparams, err, endif
      stackparams = [];
      return;
    end_try_catch

    stackparams.coefCoh.eps = stackparams.coefCoh.delta - stackparams.coefCoh.eta;
    stackparams.coefCoh.a   = 2 * stackparams.w * stackparams.coefCoh.eps - stackparams.coefCoh.delta;
    coef = stackparams.coefCoh;
    DebugPrintf ( 4, "\ncoefCoh = { delta = %g, eta = %g, nDim = %g, kappa = %g, eps = %g, a = %g }\n", coef.delta, coef.eta, coef.nDim, coef.kappa, coef.eps, coef.a );

    stackparams.coefInc.eps = stackparams.coefInc.delta - stackparams.coefInc.eta;
    stackparams.coefInc.a   = 2 * stackparams.w * stackparams.coefInc.eps - stackparams.coefInc.delta;
    coef = stackparams.coefInc;
    DebugPrintf ( 4, "\ncoefInc = { delta = %g, eta = %g, nDim = %g, kappa = %g, eps = %g, a = %g }\n", coef.delta, coef.eta, coef.nDim, coef.kappa, coef.eps, coef.a );

  endif ## !isfield(coefCoh)||!isfield(coefInc)

  stackparams.cost = stackparams.coefCoh.cost + stackparams.coefInc.cost;

  if ( !isfield ( stackparams, "misAvgLIN" ) || !isfield ( stackparams, "misAvgNLM") || !isfield ( stackparams, "misAvg" ) )
    if ( stackparams.Nseg == 1 )        ## coherent case
      stackparams.misAvgLIN = funs.misAvgLIN ( Tseg, Tobs, stackparams.mCoh, stackparams.coefCoh.xi, 0, 0 );
      stackparams.misAvgNLM = funs.misAvgNLM ( Tseg, Tobs, stackparams.mCoh, stackparams.coefCoh.xi, 0, 0 );
    elseif ( funs.par.grid_interpolation )      ## interpolating StackSlide
      stackparams.misAvgLIN = funs.misAvgLIN ( Tseg, Tobs, stackparams.mCoh, stackparams.coefCoh.xi, stackparams.mInc, stackparams.coefInc.xi );
      stackparams.misAvgNLM = funs.misAvgNLM ( Tseg, Tobs, stackparams.mCoh, stackparams.coefCoh.xi, stackparams.mInc, stackparams.coefInc.xi );
    else ## non-interpolating StackSlide
      stackparams.misAvgLIN = funs.misAvgLIN ( Tseg, Tobs, 0, 0, stackparams.mInc, stackparams.coefInc.xi );
      stackparams.misAvgNLM = funs.misAvgNLM ( Tseg, Tobs, 0, 0, stackparams.mInc, stackparams.coefInc.xi );
    endif

    if ( funs.par.nonlinearMismatch )
      stackparams.misAvg = stackparams.misAvgNLM;
    else
      stackparams.misAvg = stackparams.misAvgLIN;
    endif
  endif

  if ( !isfield ( stackparams, "L0" ) )
    stackparams.L0 = funs.L0 ( stackparams );
  endif
  if ( !isfield ( stackparams, "costConstraint" ) )
    stackparams.costConstraint = funs.costConstraint ( stackparams );
  endif

  return;

endfunction ## complete_stackparams()

## -------------------- debug output functions --------------------
function stop = DebugPrintFsolve ( v, optimValues, state )
  stop = false;

  switch state
    case 'init'
    case 'iter'
      assert ( length (v) == 2 );
      DebugPrintf ( 4, "fsolve: iter = %3d: mCoh = %g, mInc = %g -> f = %g\n", optimValues.iter, exp(v(1)), exp(v(2)), optimValues.fval );
    case 'done'
    otherwise
  endswitch
  return;
endfunction

## ---------- kept for temporary reference
function sol = NONI_unconstrained_prev ( stackparams, funs )
  global debugLevel; global powerEps;
  sol = [];
  ## ----- local shortcuts ----------
  coef = stackparams.coefInc;
  delta = coef.delta; eta = coef.eta; eps = coef.eps; a = coef.a; n = coef.nDim; k = coef.kappa; xi = coef.xi;
  w = stackparams.w;
  cost0 = funs.constraints.cost0;
  Tseg = stackparams.Tseg; Nseg = stackparams.Nseg; Tobs = Nseg * Tseg;
  ## --------------------------------

  ## check if an unconstrained solution is even deemed possible at all: did we hit one of the 'hard' boundaries?
  if ( isfield(stackparams, "hitNsegMinSemi") && stackparams.hitNsegMinSemi && (a < -powerEps) )
    DebugPrintf ( 2, "\n%s: Hit NsegMinSemi at a = %g < 0 ==> computing coherent unconstrained solution!\n", funcName, a );
    sol = COH_unconstrained ( stackparams, funs );
    return;
  endif
  if ( isfield(stackparams, "hitTsegMin") && stackparams.hitTsegMin && (a > powerEps) )
    DebugPrintf ( 2, "\n%s: Hit TsegMin at a = %g > 0 ==> giving up!\n", funcName, a );
    return;
  endif
  if ( isfield(stackparams, "hitTobsMax") && stackparams.hitTobsMax )
    if ( (a > powerEps) && (eps > powerEps) )
      DebugPrintf ( 2, "\n%s: Hit TobsMax at (a = %g > 0 && eps = %g > 0) ==> giving up!\n", funcName, a, eps );
      return;
    elseif ( (a < -powerEps) && (eps < -powerEps) )
      DebugPrintf ( 2, "\n%s: Hit TobsMax at (a = %g < 0 && eps = %g < 0) ==> giving up!\n", funcName, a, eps );
      return;
    endif

  endif

  ## ==================== Step 1: solve for optimal mismatch ====================

  ## ---------- Step 1a: check denominator zero and truncate range if required
  denom = @(logm) ( 1 - funs.misAvg ( Tseg, Tobs, 0, 0, exp(logm), xi ) );
  logmRange = log([1e-3, 1e3]);
  ## first check if denominator has a zero in this range
  if ( denom(logmRange(1)) * denom(logmRange(2)) < 0 )
    ## if yes: find it, and truncate range
    try
      [pole, residual, INFO, OUTPUT] = fzero ( denom, logmRange );
      assert( INFO == 1, ...
              "%s: fzero() failed to find pole of denominator: INFO=%i, residual=%g, iterations=%i, mcOpt=[%g,%g], FCN=[%g,%g]\n",
              funcName, INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    catch err
      DebugPrintf ( 3, "%s: 1st fzero() clause failed: trying to find mismatch range \n", funcName );
      if ( debugLevel >= 3 ) err, endif
      return;
    end_try_catch
    logmRange(2) = 0.95 * pole; ## stay below from pole
  endif ## if denominator has zero

  lhs = @(logm) funs.zInc ( Tseg, Tobs, 0, 0, exp(logm), xi ) .* exp(logm) ./ denom(logm);

  ## ---------- Step 1b: solve for mInc using Eq. obtained from (d_m L=0 and d_N L=0)
  rhs_Nseg  = (n / (2 * eta)) * ( 1 - 1/(2*w) );
  FCN_Nseg = @(logm) lhs(logm) - rhs_Nseg;
  try
    assert ( FCN_Nseg(logmRange(1)) * FCN_Nseg(logmRange(2)) < 0, "%s: logmRange [%g, %g] does not bracket mismatch solution for rhs_Nseg = %g\n", funcName, logmRange(1),logmRange(2), rhs_Nseg );
    [log_mNseg, residual, INFO, OUTPUT] = fzero ( FCN_Nseg, logmRange );
    assert( INFO == 1,
            "%s: fzero() failed to find mismatch solution for rhs_Nseg = %g: INFO=%i, residual=%g, iterations=%i, log(mcOpt)=[%g,%g], FCN=[%g,%g]\n",
            funcName, rhs_Nseg, INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    mNseg = exp ( log_mNseg );
  catch err
    DebugPrintf ( 3, "%s: 2nd fzero() clause failed: trying to solve for optimal mismatch (using d_N L=0)\n", funcName );
    if ( debugLevel >= 3) err, endif
    return;
  end_try_catch

  ## if |a| ~ 0, we're done here
  if ( abs(a) <= powerEps )
    DebugPrintf ( 3, "%s: |%a| ~ 0 ==> {Nseg = %g,Tseg = %g d} assumed optimal\n", funcName, a, stackparams.Nseg, stackparams.Tseg );
    sol = struct ( "Nseg", stackparams.Nseg, "Tseg", stackparams.Tseg, "mCoh", mNseg, "mInc", mNseg );
    return;
  endif

  ## ---------- otherwise: Step 1c: re-solve for mInc using Eq. obtained from (d_m L=0 and d_Tseg L=0)
  rhs_Tseg = n / (2 * delta );
  FCN_Tseg = @(logm) lhs(logm) - rhs_Tseg;
  try
    assert ( FCN_Tseg(logmRange(1)) * FCN_Tseg(logmRange(2)) < 0, "%s: logmRange [%g, %g] does not bracket mismatch solution for rhs_Tseg = %g\n", funcName, logmRange(1),logmRange(2), rhs_Tseg );
    [log_mTseg, residual, INFO, OUTPUT] = fzero ( FCN_Tseg, logmRange );
    assert( INFO == 1,
            "%s: fzero() failed to find mismatch solution for rhs_Tseg = %g: INFO=%i, residual=%g, iterations=%i, log(mcOpt)=[%g,%g], FCN=[%g,%g]\n",
            funcName, rhs_Tseg, INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );
    mTseg = exp ( log_mTseg );
  catch err
    DebugPrintf ( 3, "%s: 3rd fzero() clause failed: trying to solve for optimal mismatch (using d_Tseg L=0) \n", funcName );
    if ( debugLevel >= 3) err, endif
    return;
  end_try_catch

  ## we now have two mismatches, which will agree only if |a|~0, so for continuing we'll simply average them
  mNew = 0.5 * (mNseg + mTseg);

  ## ========== Step 2: devise a step in {Tseg,Nseg} in the 'right direction', proportional to |a| to ensure convergence ==========
  ## a > 0: decrease Tseg, if a < 0: increase Tseg, 'proportional' to 'a' for convergence
  ## use '-atan(a)' in [-pi/2,pi/2] in order to control the stepsize-scale
  TsegNew = stackparams.Tseg * ( 1 - atan ( a ) / pi );
  ## compute C0-consistent Nseg from this:
  logN = 1/eta * ( log(cost0/k) + n/2 * log(mNew) - delta * log(TsegNew) );
  NsegNew = exp ( logN );

  sol = struct ( "Nseg", NsegNew, "Tseg", TsegNew, "mCoh", mNew, "mInc", mNew );

  return;

endfunction ## NONI_unconstrained_prev()
