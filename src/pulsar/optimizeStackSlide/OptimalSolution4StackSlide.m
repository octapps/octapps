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
## given computing cost-functions (coherent and incoherent) and constraints (cost0, Tobs0, Nseg0...)
##
## The available options are:
##
## "costFunCoh"		coherent-cost function (handle), must be of the form cost_fun(Nseg, Tseg, mis)
## "costFunInc"		incoherent-cost function (handle), must be of the form cost_fun(Nseg, Tseg, mis)
## "cost0": 		total computing cost (in CPU seconds),
## You can optionally provide (at most) one of the following two additional constraints:
##    "Tobs0": 	 	fix total observation time
##    "Nseg0": 		fix number of segments
##
## "stackparamsGuess"	initial "guess" for solution, must contain fields {Nseg, Tseg, mc, mf}
##
## "pFA"              	false-alarm probability at which to optimize sensitivity [1e-10]
## "pFD"              	false-dismissal probability (=1-detection-probability) [0.1]
##
## "tol"              	tolerance on the obtained relative difference of the solution, required for convergence [1e-2]
## "maxiter"          	maximal allowed number of iterations [100]
##
## "xi":              	[optional] average mismatch-factor 'xi' linking average and maximal mismatch: <m> = xi * mis_max
##                    	[default = 1/3 for hypercubic lattice]
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
                       {"costFunCoh", "_function_handle" },
                       {"costFunInc", "_function_handle" },
                       {"cost0", "real,strictpos,scalar" },
                       {"Tobs0", "real,strictpos,scalar", [] },
                       {"Nseg0", "real,strictpos,scalar", [] },
                       {"stackparamsGuess", "struct", [] },
                       {"pFA", "real,strictpos,scalar", 1e-10 },
                       {"pFD", "real,strictpos,scalar", 0.1 },
                       {"xi", "real,strictpos,scalar", 1/3 },
                       {"tol", "real,strictpos,scalar", 1e-2 },
                       {"maxiter", "integer,strictpos,scalar", 100 },
                       []);

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

  constraint.cost0 = uvar.cost0;
  if ( !isempty(uvar.Tobs0) )
    constraint.Tobs0 = uvar.Tobs0;
  endif
  if ( !isempty(uvar.Nseg0) )
    constraint.Nseg0 = uvar.Nseg0;
  endif

  iter = 0;
  do
    ## determine local power-law coefficients at the current guess 'solution'
    w = SensitivityScalingDeviationN ( uvar.pFA, uvar.pFD, stackparams.Nseg );
    coef_c = LocalCostCoefficients ( uvar.costFunCoh, stackparams.Nseg, stackparams.Tseg, stackparams.mc );
    coef_f = LocalCostCoefficients ( uvar.costFunInc, stackparams.Nseg, stackparams.Tseg, stackparams.mf );

    new_stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraint, w, uvar.xi );
    if ( isempty(uvar.Tobs0) && (new_stackparams.cr == 0) )	%% unbounded solution
      new_stackparams
      error ("Unbounded solution found, need 'Tobs0' constraint!\n");
    endif
    is_converged = checkConvergence ( new_stackparams, stackparams, uvar.tol );

    stackparams = new_stackparams;

    iter ++;
  until ( is_converged || (iter > uvar.maxiter) )

  ## store some meta-info about that solution
  stackparams.converged = is_converged;
  stackparams.iter = iter;

  stackparams.w = w;
  stackparams.coef_c = coef_c;
  stackparams.coef_f = coef_f;

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
  relerr = (a - b) ./ (0.5 * (abs(a) + abs(b)) );
  return;
endfunction
