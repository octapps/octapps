## Copyright (C) 2015 Reinhard Prix
## Copyright (C) 2015 Ronaldas Macas
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
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## Usage: stackparams = OptimalSolution4StackSlide_v2 ( "option", val, "option", val, ... )
##
## Computes a *self-consistent* solution for (locally-)optimal StackSlide parameters,
## given computing cost-functions (coherent and incoherent) and constraints (cost0, TobsMax, TsegMax ...)
##
## The available options are:
##
## "costFuns":          structure containing cost function handles:
##    "costFunCoh"         coherent-cost function (handle), must be of the form cost_fun(Nseg, Tseg, mis)
##    "costFunInc"         incoherent-cost function (handle), must be of the form cost_fun(Nseg, Tseg, mis)
##
## "cost0":             total computing cost (in CPU seconds),
##
## You can optionally provide the following additional constraints:
## "TobsMax":           maximal total observation time
## "TsegMin":           minimal segment length
## "TsegMax":           maximal segment length
##
## "stackparamsGuess"   initial "guess" for solution, must contain fields {Nseg, Tseg, mCoh, mInc }
##
## "pFA"                false-alarm probability at which to optimize sensitivity [1e-10]
## "pFD"                false-dismissal probability (=1-detection-probability) [0.1]
##
## "tol"                tolerance on the obtained relative difference of the solution, required for convergence [1e-2]
## "maxiter"            maximal allowed number of iterations [30]
##
## "sensApprox":        sensitivity approximation to use in SensitivityScalingDeviationN() [default: none] {[], "none", "Gauss", "WSG}
## "nonlinearMismatch" use empirical nonlinear mismatch relation instead of linear <mis> = xi * m
##
## "debugLevel"         [optional] control level of debug output [default: 0]
##
## The return structure 'sol' has fields {Nseg, Tseg, m }
## where Nseg is the optimal (fractional!) number of segments, Tseg is the optimal segment length (in seconds)
## m is the optimal grid mismatch

function [sol, funs] = OptimalSolution4StackSlide_v2 ( varargin )

  ## do not page output
  ## pso = page_screen_output(0, "local");

  global DAYS = 86400;
  guessDefault = struct ( "Nseg", 10, "Tseg", 1 * DAYS, "m", 0.3 );

  ## parse options
  uvar = parseOptions ( varargin,
                       {"costFuns", "struct,scalar" },
                       {"cost0", "real,strictpos,scalar" },
                       {"TobsMax", "real,strictpos,scalar", [] },
                       {"TsegMin", "real,strictpos,scalar", [] },
                       {"TsegMax", "real,strictpos,scalar", [] },
                       {"stackparamsGuess", "struct", guessDefault },
                       {"pFA", "real,strictpos,scalar", 1e-10 },
                       {"pFD", "real,strictpos,scalar", 0.1 },
                       {"tol", "real,strictpos,scalar", 1e-2 },
                       {"maxiter", "integer,strictpos,scalar", 30 },
                       {"sensApprox", "char", [] },
                       {"nonlinearMismatch", "logical,scalar", false },
                       {"debugLevel", "integer,positive,scalar", 0 },
                       []);
  global powerEps; powerEps = 1e-5;	%% value practically considered "zero" for power-law coefficients
  global debugLevel; debugLevel = uvar.debugLevel;

  assert( isfield( uvar.costFuns, "costFunCoh" ) && is_function_handle( uvar.costFuns.costFunCoh ) );
  assert( isfield( uvar.costFuns, "costFunInc" ) && is_function_handle( uvar.costFuns.costFunInc ) );

  %% check and collect all (inequality) constraints
  if ( !isempty(uvar.TsegMin) && !isempty(uvar.TobsMax) )
    assert ( uvar.TsegMin <= uvar.TobsMax );
  endif
  if ( !isempty(uvar.TsegMin) && !isempty ( uvar.TsegMax ) )
    assert ( uvar.TsegMin <= uvar.TsegMax );
  endif
  if ( !isempty(uvar.TsegMax) && !isempty(uvar.TobsMax) )
    assert ( uvar.TsegMax <= uvar.TobsMax ) ;
  endif
  constraints = struct ( "cost0", uvar.cost0, "TobsMax", uvar.TobsMax, "TsegMin", uvar.TsegMin, "TsegMax", uvar.TsegMax, "NsegMinSemi", 2 );

  funs = OptimalSolution4StackSlide_v2_helpers ( uvar.costFuns, constraints, uvar.pFA, uvar.pFD, uvar.nonlinearMismatch, uvar.sensApprox );

  guess = uvar.stackparamsGuess;
  guess = funs.complete_stackparams ( guess, funs );
  if ( isempty ( guess ) ) return; endif
  DebugPrintf ( 1, "\nStarting point: "); DebugPrintStackparams ( 1, guess ); DebugPrintf ( 1, "\n" );

  i = 0;
  %% ---------- try all types of constraint combinations ------
  i++;
  trial{i}.solverFun = @(prev, funs) funs.solvers.unconstrained ( prev, funs );
  trial{i}.startGuess = guess;
  trial{i}.name = "Unconstrained";

  if ( !isempty(constraints.TobsMax) )
    i++;
    trial{i}.solverFun = @(prev, funs) funs.solvers.constrainedTobs ( prev, funs, constraints.TobsMax );
    trial{i}.startGuess = guess; trial{i}.startGuess.Tseg = constraints.TobsMax / trial{i}.startGuess.Nseg;
    trial{i}.name = "TobsMax";
  endif

  if ( !isempty(constraints.TsegMax) )
    i++;
    trial{i}.solverFun = @(prev, funs) funs.solvers.constrainedTseg ( prev, funs, constraints.TsegMax );
    trial{i}.startGuess = guess; trial{i}.startGuess.Tseg = constraints.TsegMax;
    trial{i}.name = "TsegMax";
  endif

  if ( !isempty(constraints.TsegMin) )
    i++;
    trial{i}.solverFun = @(prev, funs) funs.solvers.constrainedTseg ( prev, funs, constraints.TsegMin );
    trial{i}.startGuess = guess; trial{i}.startGuess.Tseg = constraints.TsegMin;
    trial{i}.name = "TsegMin";
  endif

  if ( !isempty(constraints.TobsMax) && !isempty(constraints.TsegMax) )
    i++;
    trial{i}.solverFun = @(prev, funs) funs.solvers.constrainedTobsTseg ( prev, funs, constraints.TobsMax, constraints.TsegMax );
    trial{i}.name = "TobsMax+TsegMax";
    trial{i}.startGuess = guess; trial{i}.startGuess.Tseg = constraints.TsegMax; trial{i}.startGuess.Nseg = constraints.TobsMax / trial{i}.startGuess.Tseg;
  endif

  if ( !isempty(constraints.TobsMax) && !isempty(constraints.TsegMin) )
    i++;
    trial{i}.solverFun = @(prev, funs) funs.solvers.constrainedTobsTseg ( prev, funs, constraints.TobsMax, constraints.TsegMin );
    trial{i}.name = "TobsMax+TsegMin";
    trial{i}.startGuess = guess; trial{i}.startGuess.Tseg = constraints.TsegMin; trial{i}.startGuess.Nseg = constraints.TobsMax / trial{i}.startGuess.Tseg;
  endif

  sol = [];
  for i = 1:length(trial)
    DebugPrintf ( 1, "----- Trying solution type '%18s':", sprintf("[%s]", trial{i}.name) );
    sol_i = iterateSolver ( trial{i}.solverFun, trial{i}.startGuess, funs, uvar.tol, uvar.maxiter );
    if ( ! isempty ( sol_i ) )
      conv = ifelse ( sol_i.converged == 0, "maxiter", ifelse ( sol_i.converged == 1, "converged", "cyclical" ) );
      DebugPrintf ( 1, "%-11s:", sprintf("[%s]", conv)); DebugPrintStackparams ( 1, sol_i );
      if ( ! constraints_violated ( sol_i, constraints, uvar.tol ) )
        if ( isempty ( sol ) || ( sol_i.L0 > sol.L0 ) )
          sol = sol_i;
          sol.name = trial{i}.name;
        endif %% if new best solution
      endif %% if !constraints violated
    endif %% if solution found
  endfor %% i : length(trial)

  if ( !isempty ( sol  ) )
    DebugPrintf ( 1, "==============================\n");
    DebugPrintf ( 1, "--> Best solution found: [@%s] ", sol.name ); DebugPrintStackparams ( 1, sol ); DebugPrintf (1, "\n" );
    DebugPrintf ( 1, "==============================\n");
  else
    DebugPrintf ( 0, "==============================\n");
    DebugPrintf ( 0, "Could not find any feasible solutions!\n" );
    DebugPrintf ( 0, "==============================\n");
  endif

  return;

endfunction %% OptimalSolution4StackSlide_v2()


function sol = iterateSolver ( solverFun, startGuess, funs, tol, maxiter )
  global DAYS;
  sol = [];

  iter = 0;
  solpath = cell();

  stackparams = startGuess;
  while true

    %% ----- saftey valve against (N,Tseg,Tobs)-constraint-violating intermediate solutions that might trip up certain cost function ----------
    if ( stackparams.Nseg < funs.constraints.NsegMinSemi )
      DebugPrintf ( 3, "\n%s: Nseg = %g < (NsegMinSemi = %d) --> setting Nseg=1\n", funcName, stackparams.Nseg, funs.constraints.NsegMinSemi );
      stackparams.Nseg = 1;
      stackparams.hitNsegMinSemi = true;	%% flag this to solvers
    endif
    if ( stackparams.Tseg < funs.constraints.TsegMin )
      DebugPrintf ( 3, "\n%s: Tseg = %g d < (TsegMin = %g d) --> resetting to Tseg=TsegMin\n", funcName, stackparams.Tseg/DAYS, funs.constraints.TsegMin/DAYS );
      stackparams.Tseg = funs.constraints.TsegMin;
      stackparams.hitTsegMin = true;    %% flag this to solvers
    endif
    if ( stackparams.Tseg > funs.constraints.TsegMax )
      DebugPrintf ( 3, "\n%s: Tseg = %g d > (TsegMax = %g d) --> resetting to Tseg=TsegMax\n", funcName, stackparams.Tseg/DAYS, funs.constraints.TsegMax/DAYS );
      stackparams.Tseg = funs.constraints.TsegMax;
      stackparams.hitTsegMax = true;    %% flag this to solvers
    endif
    if ( stackparams.Nseg * stackparams.Tseg > funs.constraints.TobsMax )
      DebugPrintf ( 3, "\n%s: Tobs = %g d > (TobsMax = %g d) --> resetting to Tobs=TobsMax\n", funcName, stackparams.Nseg*stackparams.Tseg/DAYS, funs.constraints.TobsMax/DAYS );
      stackparams.Nseg = funs.constraints.TobsMax / stackparams.Tseg;
      stackparams.hitTobsMax = true; 	%% flag this to solvers
    endif
    %% --------------------

    stackparams = funs.complete_stackparams ( stackparams, funs );
    if ( isempty ( stackparams ) )
      DebugPrintf ( 2, " ==> FAILED to even start ... (most likely cost function error)\n" );
      return;
    endif

    DebugPrintf ( 3, "\nsolver iteration = %2d:     ", iter ); DebugPrintStackparams ( 3, stackparams ); DebugPrintf ( 3, "\n" );
    if ( iter > 0 )
      stackparams.converged = checkConvergence ( stackparams, solpath, tol );
      assert ( any ( stackparams.converged == [-1, 0, 1] ), "Unknown convergence type returned by checkConvergence = %g\n", stackparams.converged);
      if ( (stackparams.converged != 0) || (iter > maxiter) )
        break;
      endif
    endif

    iter ++;
    solpath{iter} = stackparams;

    new = solverFun ( stackparams, funs );

    if ( isempty ( new ) )
      DebugPrintf ( 2, " ==> FAILED\n" );
      return;
    endif

    stepsize  = 0.9 ^ (iter - 1);
    step_Nseg = stepsize * (new.Nseg - stackparams.Nseg);
    step_Tseg = stepsize * (new.Tseg - stackparams.Tseg);
    step_mCoh = stepsize * (new.mCoh - stackparams.mCoh);
    step_mInc = stepsize * (new.mInc - stackparams.mInc);

    next.Nseg = stackparams.Nseg + step_Nseg;
    next.Tseg = stackparams.Tseg + step_Tseg;
    next.mCoh = stackparams.mCoh + step_mCoh;
    next.mInc = stackparams.mInc + step_mInc;

    stackparams = next;
  endwhile
  DebugPrintf ( 3, "\n");

  sol = stackparams;
  sol.iterations = iter;
  return;

endfunction %% iterateSolver()


function outside = constraints_violated ( sol, constraints, tol )
  %% outside = constraints_violated ( sol, constraints, tol )
  outside = 0;
  if ( !isempty(constraints.TobsMax) && (sol.Tobs > constraints.TobsMax * (1 + tol)) )
    outside = bitset ( outside, 1 );
  endif
  if ( !isempty(constraints.TsegMin) && (sol.Tseg < constraints.TsegMin * (1 - tol)) )
    outside = bitset ( outside, 2 );
  endif
  if ( !isempty(constraints.TsegMax) && (sol.Tseg > constraints.TsegMax * (1 + tol)) )
    outside = bitset ( outside, 3 );
  endif
  if ( sol.Nseg < 1 )
    outside = bitset ( outside, 4 );
  endif
  if ( sol.costConstraint > 5 * tol )	%% must be consistent with checkConvergence()
    outside = bitset ( outside, 5 );
  endif

  if ( outside > 0 )
    DebugPrintf (1, " ==> UNFEASIBLE:");
    if ( bitget ( outside, 1 ) )
      DebugPrintf (2, " [TobsMax]" );
    endif
    if ( bitget ( outside, 2 ) )
      DebugPrintf (2, " [TsegMin]" );
    endif
    if ( bitget ( outside, 3 ) )
      DebugPrintf (2, " [TsegMax]");
    endif
    if ( bitget ( outside, 4 ) )
      DebugPrintf (2, " [NsegMin]");
    endif
    if ( bitget ( outside, 5 ) )
      DebugPrintf (1, " [Cost0]");
    endif
    DebugPrintf ( 1, "\n" );
  else
    DebugPrintf (2, " ==> FEASIBLE\n");
  endif


  return;
endfunction %% constraints_violated()

function conv = checkConvergence ( new_stackparams, prev_stackparams, tol )

  if ( isempty ( prev_stackparams ) )
    conv = 0;
    return;
  endif

  tol_cost = 5 * tol;
  tol_conv = tol;
  tol_cycle = tol / 5;

  if ( isfield ( new_stackparams, "costConstraint" ) && ( new_stackparams.costConstraint > tol_cost ) )
    conv = 0;
    return;
  endif

  Nmax = length(prev_stackparams);

  for i = Nmax:-1:1
    if ( iscell( prev_stackparams) )
      prev_i = prev_stackparams{i};
    else
      prev_i = prev_stackparams;
    endif

    rel_Nseg = relError ( new_stackparams.Nseg, prev_i.Nseg );
    rel_Tseg = relError ( new_stackparams.Tseg, prev_i.Tseg );
    rel_mCoh = relError ( new_stackparams.mCoh, prev_i.mCoh );
    rel_mInc = relError ( new_stackparams.mInc, prev_i.mInc );

    if ( i == Nmax ) tol_i = tol_conv; else tol_i = tol_cycle; endif
    if ( (rel_Nseg < tol_i) && (rel_Tseg < tol_i) && (rel_mCoh < tol_i) && (rel_mInc < tol_i) )
      if ( i == Nmax )
        conv = 1;
        return;
      else
        DebugPrintf (3, "\nCycle detected at %d steps past\n", Nmax - i + 1 );
        conv = -1;
        return;
      endif
    endif

  endfor

  conv = 0;	%% not converged, no cycles detected
  return;

endfunction %% checkConvergence()

function relerr = relError ( a, b )
  if ( isna ( a ) && isna ( b ) ) relerr = 0; return; endif
  relerr = abs(a - b) ./ (0.5 * (abs(a) + abs(b)) );
  return;
endfunction %% relError()
