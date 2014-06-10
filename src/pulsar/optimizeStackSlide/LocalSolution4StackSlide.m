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

## Usage: stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraint, w=1, xi=1/3 )
## where options are:
##
## "coef_c":          structure holding local power-law coefficients { delta, kappa, nDim, [eta] }
##                    of *coherent* computing cost ~ mis^{-nDim/2} * Nseg^eta * Tseg^delta,
##                    where 'nDim' is the associated template-bank dimension.
##                    (Usually eta=1 and doesn't need to be passed, but will be used if given)
##
## "coef_f":          structure holding local power-law coefficients { delta, eta, kappa, nDim }
##                    of *incoherent* computing cost ~ mis^{-nDim/2} * Nseg^eta * Tseg^delta,
##                    where 'nDim' is the associated template-bank dimension
##
## "constraint.cost0": constraint on total computing cost
##
##                    You can optionally also provide (at most) one of the following two constraints:
## "constraint.Tobs0" [optional] constraint on total observation time
## "constraint.Nseg0" [optional] constraint on total number of segments
##
##
## "w"                Power-law correction in sensitivity Nseg-scaling: hth^{-2} ~ N^{-1/(2w)},
##                    where w=1 corresponds to the Gaussian weak-signal limit
##
## "xi":              [optional] average mismatch-factor 'xi' linking average and maximal mismatch: <m> = xi * mis_max
##                    [default = 1/3 for hypercubic lattice]
##
##
## Compute the local solution for optimal StackSlide search parameters at given (local) power-law coefficients 'coef_c', 'coef_f'
## and given computing-cost constraint 'cost0', and (optional) average-mismatch geometrical factor 'xi' in [0,1]
##
## NOTE: this solution is *not* guaranteed to be self-consistent, in the sense that the power-law coefficients
## at the point of this local solution may be different from the input 'coef_c', 'coef_f'
##
## Return structure 'stackparams' has fields {Nseg, Tseg, mc, mf, cr }
## where Nseg is the optimal (fractional!) number of segments, Tseg is the optimal segment length (in seconds),
## mc is the optimal coarse-grid maximal mismatch, mf the optimal fine-grid maximal mismatch, and cr the resulting optimal
## computing-cost ratio, i.e. cr = CostCoh / CostIncoh.
##
## [Equation numbers refer to Prix&Shaltev, PRD85, 084010 (2012)]
##

function stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraint, w = 1, xi = 1/3 )

  %% check user-input sanity
  assert ( !isempty( constraint ) );

  assert ( isfield ( constraint, "cost0" ) );
  cost0 = constraint.cost0;
  assert ( cost0 > 0 );

  have_Tobs0 = isfield ( constraint, "Tobs0" );
  have_Nseg0 = isfield ( constraint, "Nseg0" );
  assert ( !have_Tobs0 || (constraint.Tobs0 > 0) );
  assert ( !have_Nseg0 || (constraint.Nseg0 > 0 ) );
  assert ( !(have_Tobs0 && have_Nseg0 ) );

  assert ( ! isempty ( coef_c ) );
  assert ( ! isempty ( coef_f ) );

  assert ( isfield ( coef_c, "delta" ) );
  assert ( isfield ( coef_c, "kappa" ) );
  assert ( isfield ( coef_c, "nDim" ) );

  assert ( isfield ( coef_f, "delta" ) );
  assert ( isfield ( coef_f, "eta" ) );
  assert ( isfield ( coef_f, "kappa" ) );
  assert ( isfield ( coef_f, "nDim" ) );

  %% coherent power-law coefficients
  delta_c = coef_c.delta;
  kappa_c = coef_c.kappa;
  n_c     = coef_c.nDim;
  eta_c   = 1;	## default value for all 'standard' cases
  if ( isfield ( coef_c, "eta" ) )
    eta_c = coef_c.eta;	## ... but we allow to override this
  endif

  %% incoherent power-law coefficients
  delta_f = coef_f.delta;
  kappa_f = coef_f.kappa;
  n_f     = coef_f.nDim;
  eta_f   = coef_f.eta;

  %% derived quantities 'epsilon' of Eq.(66)
  eps_c   = delta_c - eta_c;
  eps_f   = delta_f - eta_f;
  %% and 'critical exponent' a of Eq.(77)
  a_c = 2 * w * eps_c - delta_c;
  a_f = 2 * w * eps_f - delta_f;
  assert ( a_c > 0 );

  %% coefficient-matrix determinant of Eq.(88)
  D = delta_c * eta_f - delta_f * eta_c;
  assert ( D > 0 );
  Dinv = 1/D;

  %% ----- asymptotic mismatches, Eq.(78):
  m0_c = ( xi * ( 1 + 4 * w * eps_c / n_c ) )^(-1);
  m0_f = ( xi * ( 1 + 4 * w * eps_f / n_f ) )^(-1);

  %% ----- optimal mismatches as functions of 'cr', Eq.(94)
  mcOpt_fcr = @(cr) ( ( 1 / m0_c ) + ( cr^(-1) / m0_f ) * ( n_f / n_c ) )^(-1);
  mfOpt_fcr = @(cr) ( ( 1 / m0_f ) + ( cr      / m0_c ) * ( n_c / n_f ) )^(-1);

  %% ----- construct optimal Nseg(cr), Tobs(cr) given by Eqs.(86,87):

  %% cost prefactors in Eqs.(86,87) [avoiding overflow]
  log_c0_kappa_f     = log ( cost0 / kappa_f );
  log_c0_kappa_c     = log ( cost0 / kappa_c );
  log_cost_fact_Nseg = delta_c * log_c0_kappa_f - delta_f * log_c0_kappa_c;
  log_cost_fact_Tobs = eps_c   * log_c0_kappa_f - eps_f   * log_c0_kappa_c;
  cost_fact_Nseg     = exp ( log_cost_fact_Nseg );
  cost_fact_Tobs     = exp ( log_cost_fact_Tobs );

  termU = @(cr) (mcOpt_fcr(cr))^(-0.5*n_c) * ( 1 + cr^(-1) );
  termL = @(cr) (mfOpt_fcr(cr))^(-0.5*n_f) * ( 1 + cr );

  misfract_Nseg = @(cr) (termU(cr))^delta_f / (termL(cr))^delta_c;	%% main fraction term in Eq.(86)
  misfract_Tobs = @(cr) (termU(cr))^eps_f   / (termL(cr))^eps_c;	%% main fraction term in Eq.(87)

  NsegOpt_fcr = @(cr) ( cost_fact_Nseg * misfract_Nseg(cr) )^Dinv;	%% Eq.(86) for Nseg(cr)
  TobsOpt_fcr = @(cr) ( cost_fact_Tobs * misfract_Tobs(cr) )^Dinv;	%% Eq.(87) for Tobs(cr)

  %% ----- 3 possible ways to determine the optimal computing-cost ratio 'crOpt':
  %% *) unconstrained: use Eq.(103) ==> {bounded, unbounded}
  %% *) given constraint Nseg0: solve Eq.(86) Nseg(crOpt) = Nseg0
  %% *) given constraint Tobs0: solve Eq.(87) Tobs(crOpt) = Tobs0

  if ( !have_Tobs0 && !have_Nseg0 )

    if ( a_f < 0 )		%% we always have a_c > 0
      crOpt = -a_f / a_c;	%% Eq.(103): bounded solution
    else
      crOpt = 0; 		%% unbounded solution
    endif

  elseif ( have_Tobs0 )
    Tobs0 = constraint.Tobs0;
    %% solve computing-cost ratio equation Eq.(87) for given Tobs
    lhsTobs = Tobs0^D / cost_fact_Tobs;
    deltaTobs_fcr = @(cr) misfract_Tobs(cr) - lhsTobs;

    x0 = [1e-6, 1e6];
    try
      [crOpt, residual, INFO, OUTPUT] = fzero ( deltaTobs_fcr, x0 );
    catch
      error ("CATCH: fzero() failed to find Tobs0-constrained solution for crOpt.\n");
    end_try_catch
    assert ( INFO == 1, "Tobs-constrained solution failed to converge, residual = %f, OUTPUT = '%s'\n", {residual, OUTPUT} );

  elseif ( have_Nseg0 )

    %% solve computing-cost ratio equation Eq.(86) for given Nseg
    lhsNseg = constraint.Nseg0^D / cost_fact_Nseg;
    deltaNseg_fcr = @(cr) misfract_Nseg(cr) - lhsNseg;

    x0 = [1e-6, 1e6];
    if ( deltaNseg_fcr(x0(1)) * deltaNseg_fcr(x0(2)) >= 0 )
      error ("No solution expected for Nseg-constrained in the range cr in [%g, %g] .. giving up.\n", x0(1), x0(2) );
    endif
    try
      [crOpt, residual, INFO, OUTPUT] = fzero ( deltaNseg_fcr, x0 );
    catch
      error ("CATCH: fzero() failed to find Nseg-constrained solution for crOpt.\n");
    end_try_catch
    assert ( INFO == 1, "Nseg-constrained solution failed to converge, residual = %f, OUTPUT = '%s'\n", {residual, OUTPUT} );

  else
    error ("Logical error!\n");
  endif

  %% compute all derived quantities from crOpt
  mcOpt    = mcOpt_fcr ( crOpt );
  mfOpt    = mfOpt_fcr ( crOpt );
  TobsOpt  = TobsOpt_fcr ( crOpt );
  NsegOpt  = NsegOpt_fcr ( crOpt );

  %% package this into return-struct 'stackparams'
  stackparams.mc 	= mcOpt;
  stackparams.mf 	= mfOpt;
  stackparams.Nseg 	= NsegOpt;
  stackparams.Tseg 	= TobsOpt / NsegOpt;
  stackparams.cr   	= crOpt;

  return;

endfunction

%!test
%!  %% check recovery of published results in Prix&Shaltev(2012): V.A: directed CasA
%!  coef_c.nDim = 2;
%!  coef_c.delta = 4.00;
%!  coef_c.kappa = 3.1358511e-17;
%!
%!  coef_f.nDim = 3;
%!  coef_f.delta = 6.0;
%!  coef_f.eta = 4;
%!  coef_f.kappa = 2.38382054e-33;
%!
%!  constraint.cost0 = 471.981444 * 86400;
%!  xi = 0.5;
%!  stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraint, w = 1, xi );
%!  assert ( stackparams.cr, 1, 1e-6 );			## Eq.(117)
%!  assert ( stackparams.mc, 0.16, 1e-6 );		## Eq.(118)
%!  assert ( stackparams.mf, 0.24, 1e-6 );		## Eq.(118)
%!  assert ( stackparams.Tseg / 86400, 2.3448, 1e-3 );	## corrected result, found in Shaltev thesis, Eq.(4.119)
%!  assert ( stackparams.Nseg, 61.7557, 1e-4 );		## corrected result, found in Shaltev thesis, Eq.(4.119)

%!test
%!  %% check recovery of published results in Prix&Shaltev(2012): V.B: all-sky E@H [S5GC1], TableII
%!  coef_c.nDim = 4;
%!  coef_c.delta = 10.0111962295912;
%!  coef_c.kappa = 9.09857109479269e-50;
%!
%!  coef_f.nDim = 4;
%!  coef_f.delta = 9.01119622959135;
%!  coef_f.eta = 2;
%!  coef_f.kappa = 1.56944271959491e-47;
%!
%!  constraint.cost0 = 3258.42235987226;
%!  constraint.Tobs0 = 365*86400;
%!  xi = 1/3;
%!  pFA = 1e-10; pFD = 0.1;
%!  NsegRef = 527.6679900489286;
%!  w = SensitivityScalingDeviationN ( pFA, pFD, NsegRef );
%!  assert ( w, 1.09110798102039, 1e-6 );
%!  stackparams = LocalSolution4StackSlide ( coef_c, coef_f, constraint, w, xi );
%!  assert ( stackparams.cr, 0.869163870996078, 1e-4 );
%!  assert ( stackparams.mc, 0.144345898957936, 1e-4 );
%!  assert ( stackparams.mf, 0.1660744351839173, 1e-4 );
%!  assert ( stackparams.Tseg, 59764.8513746905, -1e-4 );
%!  assert ( stackparams.Nseg, NsegRef, -1e-4 );

