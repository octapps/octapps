## Copyright (C) 2014 Reinhard Prix
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

## Usage: stackparams = OptimalSolution4StackSlide ( "option", val, "option", val, ... )
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
## "TsegMax":           maximal segment length
##
## "stackparamsGuess"   initial "guess" for solution, must contain fields {Nseg, Tseg, mc, mf}
##
## "pFA"                false-alarm probability at which to optimize sensitivity [1e-10]
## "pFD"                false-dismissal probability (=1-detection-probability) [0.1]
##
## "tol"                tolerance on the obtained relative difference of the solution, required for convergence [1e-2]
## "maxiter"            maximal allowed number of iterations [100]
##
## "xi":                [optional] average mismatch-factor 'xi' linking average and maximal mismatch: <m> = xi * mis_max
##                      [default = 1/3 for hypercubic lattice]
##
## The return structure 'stackparams' has fields {Nseg, Tseg, mc, mf, cr }
## where Nseg is the optimal (fractional!) number of segments, Tseg is the optimal segment length (in seconds)
## mc is the optimal coarse-grid mismatch, mf the optimal fine-grid mismatch, and cr the resulting optimal
## computing-cost ratio, i.e. cr = CostCoh / CostIncoh.
##
## [Equation numbers refer to Prix&Shaltev, PRD85, 084010 (2012)]
##

function stackparams = OptimalSolution4StackSlide ( varargin )

  ## parse options
  uvar = parseOptions ( varargin,
                       {"costFuns", "struct,scalar" },
                       {"cost0", "real,strictpos,scalar" },
                       {"TobsMax", "real,strictpos,scalar", [] },
                       {"TsegMax", "real,strictpos,scalar", [] },
                       {"stackparamsGuess", "struct", [] },
                       {"pFA", "real,strictpos,scalar", 1e-10 },
                       {"pFD", "real,strictpos,scalar", 0.1 },
                       {"xi", "real,strictpos,scalar", 1/3 },
                       {"tol", "real,strictpos,scalar", 1e-2 },
                       {"maxiter", "integer,strictpos,scalar", 100 },
                       []);
  assert( isfield( uvar.costFuns, "costFunCoh" ) && is_function_handle( uvar.costFuns.costFunCoh ) );
  assert( isfield( uvar.costFuns, "costFunInc" ) && is_function_handle( uvar.costFuns.costFunInc ) );

  ## if no initial guess given, use a simple one
  if ( isempty ( uvar.stackparamsGuess ) )
    stackparams.Nseg = 10;
    stackparams.Tseg = 86400;
    stackparams.mc   = 0.3;
    stackparams.mf   = 0.3;
  else
    stackparams = uvar.stackparamsGuess;
    assert (isfield ( stackparams, "Nseg" ) &&
            isfield ( stackparams, "Tseg" ) &&
            isfield ( stackparams, "mc" ) &&
            isfield ( stackparams, "mf" )
            );
  endif

  %% ----- handle different levels of constraints ----------
  constraints0.cost0 = uvar.cost0;

  if ( !isempty(uvar.TobsMax) )
    have_TobsMax = true;
    assert ( uvar.TobsMax > 0 );
    constraintsTobs = constraints0;
    constraintsTobs.Tobs0 = uvar.TobsMax;
  else
    have_TobsMax = false;
  endif

  if ( !isempty(uvar.TsegMax) )
    have_TsegMax = true;
    assert ( uvar.TsegMax > 0 );
    assert ( have_TobsMax, "Constraint 'TobsMax' required if given 'TsegMax'\n");
    constraintsTseg = constraints0;
    constraintsTseg.Tobs0 = uvar.TobsMax;
    constraintsTseg.Tseg0 = uvar.TsegMax;
  else
    have_TsegMax = false;
  endif

  is_converged = false;
  iter = 0;
  while true

    ## determine local power-law coefficients at the current guess 'solution'
    w = SensitivityScalingDeviationN ( uvar.pFA, uvar.pFD, stackparams.Nseg );
    coef_c = LocalCostCoefficients ( uvar.costFuns.costFunCoh, stackparams.Nseg, stackparams.Tseg, stackparams.mc );
    coef_f = LocalCostCoefficients ( uvar.costFuns.costFunInc, stackparams.Nseg, stackparams.Tseg, stackparams.mf );

    ## store some meta-info about the solution
    stackparams.converged = is_converged;
    stackparams.iter = iter;
    stackparams.w = w;
    stackparams.coef_c = coef_c;
    stackparams.coef_f = coef_f;
    stackparams.cost = coef_c.cost + coef_f.cost;
    stackparams.cr = coef_c.cost / coef_f.cost;

    if ( is_converged || ( ++iter >= uvar.maxiter ) )
      break
    endif

    ## compute new guess 'solution'
    new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraints0, w, uvar.xi );

    %% ----- check special failure modes and handle them separately ----------
    if ( isfield(new_stackparams,"need_TsegMax") && new_stackparams.need_TsegMax )
      assert ( have_TobsMax && have_TsegMax, "LocalSolution4StackSlide() asked for both 'TobsMax' and 'TsegMax' constraints\n");
      new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTseg, w, uvar.xi );
    elseif ( isfield(new_stackparams,"need_TobsMax") && new_stackparams.need_TobsMax )
      assert ( have_TobsMax, "LocalSolution4StackSlide() asked for 'TobsMax' constraint!\n");
      new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTobs, w, uvar.xi );
    endif
    %% ----- sucess, but check if constraints violated, if yes need to recompute:
    Tobs = new_stackparams.Nseg * new_stackparams.Tseg;
    if ( have_TobsMax && (Tobs > uvar.TobsMax) )
      new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTobs, w, uvar.xi );
    endif
    if ( have_TsegMax && (new_stackparams.Tseg > uvar.TsegMax ) )
      new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTseg, w, uvar.xi );
    endif

    is_converged = checkConvergence ( new_stackparams, stackparams, uvar.tol );

    stackparams = new_stackparams;

  endwhile

  return;

endfunction


function is_converged = checkConvergence ( new_stackparams, stackparams, tol )

  rel_Nseg = relError ( new_stackparams.Nseg, stackparams.Nseg );
  rel_Tseg = relError ( new_stackparams.Tseg, stackparams.Tseg );
  rel_mc   = relError ( new_stackparams.mc,   stackparams.mc );
  rel_mf   = relError ( new_stackparams.mf,   stackparams.mf );

  if ( (rel_Nseg < tol) && (rel_Tseg < tol) && (rel_mc < tol) && (rel_mf < tol) )
    is_converged = true;
  else
    is_converged = false;
  endif

  return;

endfunction

function relerr = relError ( a, b )
  relerr = abs(a - b) ./ (0.5 * (abs(a) + abs(b)) );
  return;
endfunction


## Recomputes the E@H S5GC1 solution given in Prix&Shaltev,PRD85,084010(2012) Table~II
## and compares with reference result. This function either passes or fails depending on the result.
%!test
%!
%!  refParams.Nseg = 205;
%!  refParams.Tseg = 25 * 3600;	## 25(!) hours
%!  refParams.mc   = 0.5;
%!  refParams.mf   = 0.5;
%!
%!  costFuns = EaHS5GC1CostFunctions();
%!
%!  cost_co = costFuns.costFunCoh(refParams.Nseg, refParams.Tseg, refParams.mc );
%!  cost_ic = costFuns.costFunInc(refParams.Nseg, refParams.Tseg, refParams.mf );
%!  cost0 = cost_co + cost_ic;
%!  TobsMax = 365 * 86400;
%!
%!  sol = OptimalSolution4StackSlide ( "costFuns", costFuns, "cost0", cost0, "TobsMax", TobsMax, "stackparamsGuess", refParams );
%!
%!  tol = -1e-3;
%!  assert ( sol.mc, 0.1443, tol );
%!  assert ( sol.mf, 0.1660, tol );
%!  assert ( sol.Nseg, 527.7, tol );
%!  assert ( sol.Tseg, 59762, tol );
%!  assert ( sol.cr, 0.8691, tol );
