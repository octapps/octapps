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
## "TsegMin":           minimal segment length
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
## "sensApprox":        sensitivity approximation to use in SensitivityScalingDeviationN() [default: none] {[], "none", "Gauss", "WSG}
##
## "verbose"            [optional] print useful information about solution at each iteration [default: false]
##
## The return structure 'stackparams' has fields {Nseg, Tseg, mc, mf, cr }
## where Nseg is the optimal (fractional!) number of segments, Tseg is the optimal segment length (in seconds)
## mc is the optimal coarse-grid mismatch, mf the optimal fine-grid mismatch, and cr the resulting optimal
## computing-cost ratio, i.e. cr = CostCoh / CostIncoh.
##
## [Equation numbers refer to Prix&Shaltev, PRD85, 084010 (2012)]
##

function stackparams = OptimalSolution4StackSlide ( varargin )

  ## do not page output
  pso = page_screen_output(0, "local");

  ## load constants
  UnitsConstants;

  ## parse options
  uvar = parseOptions ( varargin,
                       {"costFuns", "struct,scalar" },
                       {"cost0", "real,strictpos,scalar" },
                       {"TobsMax", "real,strictpos,scalar", [] },
                       {"TsegMin", "real,strictpos,scalar", [] },
                       {"TsegMax", "real,strictpos,scalar", [] },
                       {"stackparamsGuess", "struct", [] },
                       {"pFA", "real,strictpos,scalar", 1e-10 },
                       {"pFD", "real,strictpos,scalar", 0.1 },
                       {"tol", "real,strictpos,scalar", 1e-2 },
                       {"maxiter", "integer,strictpos,scalar", 100 },
                       {"verbose", "logical,scalar", false },
                       {"sensApprox", "char", [] },
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

  have_TobsMax = !isempty(uvar.TobsMax);
  if ( have_TobsMax )
    assert ( uvar.TobsMax > 0 );
    constraintsTobs = constraints0;
    constraintsTobs.Tobs0 = uvar.TobsMax;
  endif

  have_TsegMin = !isempty(uvar.TsegMin);
  if ( have_TsegMin )
    assert ( uvar.TsegMin > 0 );
    assert ( have_TobsMax, "Constraint 'TobsMax' required if given 'TsegMin'\n");
    constraintsTsegMin = constraints0;
    constraintsTsegMin.Tobs0 = uvar.TobsMax;
    constraintsTsegMin.Tseg0 = uvar.TsegMin;
  endif

  have_TsegMax = !isempty(uvar.TsegMax);
  if ( have_TsegMax )
    if ( have_TsegMin )
      assert ( uvar.TsegMax > uvar.TsegMin );
    else
      assert ( uvar.TsegMax > 0 );
    endif
    assert ( have_TobsMax, "Constraint 'TobsMax' required if given 'TsegMax'\n");
    constraintsTsegMax = constraints0;
    constraintsTsegMax.Tobs0 = uvar.TobsMax;
    constraintsTsegMax.Tseg0 = uvar.TsegMax;
  endif

  is_converged = false;
  iter = 0;
  while true

    ## determine local power-law coefficients at the current guess 'solution'
    w = SensitivityScalingDeviationN ( uvar.pFA, uvar.pFD, stackparams.Nseg, uvar.sensApprox );
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

    if ( uvar.verbose )
      printf("\n%s iteration %i", funcName(), stackparams.iter);
      if ( stackparams.converged )
        printf(" has converged!\n");
      else
        printf(":\n");
      endif
      printf("  Nseg = %g, Tseg = %g days, mc = %g, mf = %g\n", stackparams.Nseg, stackparams.Tseg/DAYS, stackparams.mc, stackparams.mf);
      printf("  cost_coh ~ Nseg^%g * Tseg^%g * mc^(-%g/2)\n", stackparams.coef_c.eta, stackparams.coef_c.delta, stackparams.coef_c.nDim);
      printf("  cost_inc ~ Nseg^%g * Tseg^%g * mc^(-%g/2)\n", stackparams.coef_f.eta, stackparams.coef_f.delta, stackparams.coef_f.nDim);
      printf("  cost / cost0 = %0.2e sec / %0.2e sec = %g\n", stackparams.cost, uvar.cost0, stackparams.cost / uvar.cost0);
      if ( have_TobsMax )
        Tobs = stackparams.Nseg * stackparams.Tseg;
        printf("  Tobs / TobsMax = %0.2e days / %0.2e days = %g\n", Tobs/DAYS, uvar.TobsMax/DAYS, Tobs / uvar.TobsMax);
      endif
      printf("\n");
    endif

    if ( is_converged || ( ++iter >= uvar.maxiter ) )
      break
    endif

    ## compute new guess 'solution'
    new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraints0, w );

    %% ----- check special failure modes and handle them separately ----------
    need_TsegMax = isfield(new_stackparams,"need_TsegMax") && new_stackparams.need_TsegMax;
    need_TobsMax = isfield(new_stackparams,"need_TobsMax") && new_stackparams.need_TobsMax;
    if ( need_TsegMax )
      if ( need_TobsMax )
        assert ( have_TobsMax && have_TsegMax, "LocalSolution4StackSlide() asked for both 'TobsMax' and 'TsegMax' constraints\n");
        new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTsegMax, w );
      else
        error ("Currently only handle the case when requiring 'TsegMax' also requires 'TobsMax'\n");
      endif
    elseif ( need_TobsMax )
      assert ( have_TobsMax, "LocalSolution4StackSlide() asked for 'TobsMax' constraint!\n");
      new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTobs, w );
    endif
    %% ----- sucess, but check if constraints violated, if yes need to recompute:
    Tobs = new_stackparams.Nseg * new_stackparams.Tseg;
    if ( have_TobsMax && (Tobs > uvar.TobsMax) )
      new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTobs, w );
    endif
    if ( have_TsegMin && (new_stackparams.Tseg < uvar.TsegMin ) )
      new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTsegMin, w );
    endif
    if ( have_TsegMax && (new_stackparams.Tseg > uvar.TsegMax ) )
      new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraintsTsegMax, w );
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
