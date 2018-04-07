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

## Usage: stackparams = LocalSolution4StackSlide ( coefCoh, coefInc, constraints, w = 1, lattice = "Zn" )
## where options are:
##
## "coefCoh":          structure holding local power-law coefficients { delta, kappa, nDim, [eta] } and lattice type
##                    of *coherent* computing cost ~ mis^{-nDim/2} * Nseg^eta * Tseg^delta,
##                    where 'nDim' is the associated template-bank dimension.
##                    (Usually eta=1 and doesn't need to be passed, but will be used if given)
##
## "coefInc":          structure holding local power-law coefficients { delta, eta, kappa, nDim } and lattice type
##                    of *incoherent* computing cost ~ mis^{-nDim/2} * Nseg^eta * Tseg^delta,
##                    where 'nDim' is the associated template-bank dimension
##
## "constraints":     struct holding the following fields specifying constraints:
## {
##       "cost0":     constraint on total computing cost
##
##                    and the following _optional_ additional constraints:
##     "Tobs0":       constraint on total observation time
##     "Tseg0":       constraint on segment length
## }
##
##
## "w"                Power-law correction in sensitivity Nseg-scaling: hth^{-2} ~ N^{-1/(2w)},
##                    where w=1 corresponds to the Gaussian weak-signal limit
##
## Compute the local solution for optimal StackSlide search parameters at given (local) power-law coefficients 'coefCoh', 'coefInc'
## and given computing-cost constraint 'cost0'.
##
## NOTE: this solution is *not* guaranteed to be self-consistent, in the sense that the power-law coefficients
## at the point of this local solution may be different from the input 'coefCoh', 'coefInc'
##
## Return structure 'stackparams' has fields {Nseg, Tseg, mCoh, mInc, cr }
## where Nseg is the optimal (fractional!) number of segments, Tseg is the optimal segment length (in seconds),
## mCoh is the optimal coherent-grid maximal mismatch, mInc the optimal incoherent-grid maximal mismatch, and cr the resulting optimal
## computing-cost ratio, i.e. cr = CostCoh / CostIncoh.
##
## [Equation numbers refer to Prix&Shaltev, PRD85, 084010 (2012)]
##

function stackparams = LocalSolution4StackSlide ( coefCoh, coefInc, constraints, w = 1 )

  ## check user-input sanity
  assert ( !isempty( constraints ) );

  assert ( isfield ( constraints, "cost0" ) );
  cost0 = constraints.cost0;
  assert ( cost0 > 0 );

  have_Tobs0 = isfield ( constraints, "Tobs0" );
  assert ( !have_Tobs0 || (constraints.Tobs0 > 0) );
  have_Tseg0 = isfield ( constraints, "Tseg0" );
  assert ( !have_Tseg0 || (constraints.Tseg0 > 0) );
  assert ( !(have_Tseg0 && !have_Tobs0), "Constraint 'Tseg0' only valid together with 'Tobs0'\n");

  assert ( ! isempty ( coefCoh ) );
  assert ( ! isempty ( coefInc ) );

  assert ( isfield ( coefCoh, "delta" ) );
  assert ( isfield ( coefCoh, "kappa" ) );
  assert ( isfield ( coefCoh, "nDim" ) );
  assert ( isfield ( coefCoh, "lattice" ) && ischar ( coefCoh.lattice ) );

  assert ( isfield ( coefInc, "delta" ) );
  assert ( isfield ( coefInc, "eta" ) );
  assert ( isfield ( coefInc, "kappa" ) );
  assert ( isfield ( coefInc, "nDim" ) );
  assert ( isfield ( coefInc, "lattice" ) && ischar ( coefInc.lattice ) );

  ## coherent power-law coefficients
  delta_c = coefCoh.delta;
  kappa_c = coefCoh.kappa;
  n_c     = coefCoh.nDim;
  eta_c   = 1;  ## default value for all 'standard' cases
  if ( isfield ( coefCoh, "eta" ) )
    eta_c = coefCoh.eta;        ## ... but we allow user-input to override this
  endif

  ## incoherent power-law coefficients
  delta_f = coefInc.delta;
  kappa_f = coefInc.kappa;
  n_f     = coefInc.nDim;
  eta_f   = coefInc.eta;

  ## derived quantities 'epsilon' of Eq.(66)
  eps_c   = delta_c - eta_c;
  eps_f   = delta_f - eta_f;

  ## ----- average mismatch factor linking average and maximal mismatch for lattices used
  xi_c = coefCoh.xi;
  xi_f = coefInc.xi;

  ## degenerate case can only be solved with Tseg0 and Tobs0 constraints
  if ( (abs(eps_c) < 1e-6) && (abs(eps_f) < 1e-6 ) )
    if ( !(have_Tobs0 && have_Tseg0) )
      ## warning ( "Degenerate case (eps_c=eps_f=0), need both constraints 'Tobs0' and 'Tseg0'\n");
      stackparams.need_TsegMax = true;
      stackparams.need_TobsMax = true;
      return;
    else
      ## warning ("Degenerate case, using constraints Tobs0=%g, Tseg0=%g!\n", constraints.Tobs0, constraints.Tseg0 );
    endif
  endif

  ## ----- first: special handling of Tobs0 + Tseg0 constrained case ----------
  if ( have_Tobs0 && have_Tseg0 )
    Tobs0 = constraints.Tobs0;
    Tseg0 = constraints.Tseg0;
    Nseg0 = Tobs0/Tseg0;

    Tau0 = (kappa_c * n_c)/(kappa_f * n_f) * Tobs0^(delta_c - delta_f) * Nseg0^(-eps_c + eps_f);
    cost0_fmf = @(m_f) (kappa_c) * m_f.^(-n_c/2 * (n_f + 2) / (n_c + 2)) * Tau0^(-n_c/(n_c+2)) * Tobs0^delta_c * Nseg0^(-eps_c) + (kappa_f) * m_f.^(-n_f/2) * Tobs0^delta_f * Nseg0^(-eps_f);
    eq0_fmf = @(m_f) cost0_fmf(m_f)/cost0 - 1;

    ## try to go with wide bounds for mfOpt, check if sign change
    x0 = [0, 1e4];
    if ( eq0_fmf( x0(1) )  * eq0_fmf ( x0(2) ) >= 0 )
      error( "No sign change for eq0_fmf(x) betweeen x0=%g and x1=%g, fzero() won't work!\n", x0(1), x0(2) );
    endif
    [mfOpt, residual, INFO, OUTPUT] = fzero ( eq0_fmf, x0 );
    assert( INFO == 1,
            "fzero() failed to find cost solution for mfOpt in degenerate case: INFO=%i, residual=%g, iterations=%i, mfOpt=[%g,%g], eq0_fmf=[%g,%g]\n",
            INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );

    mcOpt = mfOpt^((n_f + 2)/(n_c+2)) * Tau0^(2/(n_c+2));
    crOpt = (mcOpt/n_c)/(mfOpt/n_f);

    stackparams.mInc = mfOpt;
    stackparams.mCoh = mcOpt;
    stackparams.cr   = crOpt;
    stackparams.Tseg = Tseg0;
    stackparams.Nseg = Nseg0;
    return;

  endif

  ## ----- then: handle unconstrained and Tobs0-constrained cases ----------

  ## and 'critical exponent' a of Eq.(77)
  a_c = 2 * w * eps_c - delta_c;
  a_f = 2 * w * eps_f - delta_f;

  ## coefficient-matrix determinant of Eq.(88)
  D = delta_c * eta_f - delta_f * eta_c;
  ## in some extreme cases (e.g. supersky metrics with T < 1 day),
  ## D can become negative, so only require that it be nonzero.
  assert ( D != 0, "Failed assertion: D = %g * %g - %g * %g != 0", delta_c, eta_f, delta_f, eta_c );
  Dinv = 1/D;

  ## ----- asymptotic mismatches, Eq.(78):
  m0_c = ( xi_c * ( 1 + 4 * w * eps_c / n_c ) )^(-1);
  m0_f = ( xi_f * ( 1 + 4 * w * eps_f / n_f ) )^(-1);

  ## ----- optimal mismatches as functions of 'cr', Eq.(94)
  ## restrict mismatches to be >= 1e-3 to prevent numerical problems in later equations
  mcOpt_fcr = @(cr) max( 1e-3, ( ( 1 / m0_c ) + ( cr^(-1) / m0_f ) * ( n_f / n_c ) )^(-1) );
  mfOpt_fcr = @(cr) max( 1e-3, ( ( 1 / m0_f ) + ( cr      / m0_c ) * ( n_c / n_f ) )^(-1) );

  ## ----- construct optimal Nseg(cr), Tobs(cr) given by Eqs.(86,87):

  ## cost prefactors in Eqs.(86,87) [avoiding overflow]
  log_c0_kappa_f     = log ( cost0 / kappa_f );
  log_c0_kappa_c     = log ( cost0 / kappa_c );
  termU = @(cr) (mcOpt_fcr(cr))^(-0.5*n_c) * ( 1 + cr^(-1) );
  termL = @(cr) (mfOpt_fcr(cr))^(-0.5*n_f) * ( 1 + cr );
  misfract_Nseg = @(cr) (termU(cr))^delta_f / (termL(cr))^delta_c;      ## main fraction term in Eq.(86)
  misfract_Tobs = @(cr) (termU(cr))^eps_f   / (termL(cr))^eps_c;        ## main fraction term in Eq.(87)
  log_cost_fact_Nseg = delta_c * log_c0_kappa_f - delta_f * log_c0_kappa_c;
  log_cost_fact_Tobs = eps_c * log_c0_kappa_f - eps_f * log_c0_kappa_c;
  cost_fact_Nseg     = exp ( log_cost_fact_Nseg );
  cost_fact_Tobs     = exp ( log_cost_fact_Tobs );
  TobsOpt_fcr = @(cr) ( cost_fact_Tobs * misfract_Tobs(cr) )^Dinv;      ## Eq.(87) for Tobs(cr)
  NsegOpt_fcr = @(cr) ( cost_fact_Nseg * misfract_Nseg(cr) )^Dinv;      ## Eq.(86) for Nseg(cr)

  ## ----- compute optimal solution for different given constraints ----------
  if ( !have_Tobs0 )
    crOpt = -a_f / a_c;         ## Eq.(103): if bounded solution
    if ( crOpt <= 0 )
      stackparams.need_TobsMax = true;
    endif
  else
    ## solve **log of** computing-cost ratio equation Eq.(87) for given Tobs
    log_lhsTobs = D * log( constraints.Tobs0 ) - log_cost_fact_Tobs;
    log_deltaTobs_fcr = @(cr) log( misfract_Tobs(cr) ) - log_lhsTobs;

    ## try to find working bounds for crOpt
    x = logspace( -10, 10, 500 );
    y = arrayfun( @(x) log_deltaTobs_fcr(x), x );
    [ymax, imax] = max( y );
    [ymin, imin] = min( y );
    if ( ymin * ymax < 0 )
      x0 = [ x(imin), x(imax) ];
    else
      error( "Could not bound crOpt for Tobs0-constrained solution" );
    endif

    [crOpt, residual, INFO, OUTPUT] = fzero ( log_deltaTobs_fcr, x0 );
    assert( INFO == 1 || ( INFO == -5 && abs( diff( OUTPUT.bracketx ) ) < 1e-3 ),
            "fzero() failed to find Tobs0-constrained solution for crOpt: INFO=%i, residual=%g, iterations=%i, crOpt=[%g,%g], log_deltaTobs_fcr=[%g,%g]\n",
            INFO, residual, OUTPUT.iterations, OUTPUT.bracketx(1), OUTPUT.bracketx(2), OUTPUT.brackety(1), OUTPUT.brackety(2) );

  endif

  ## compute all derived quantities from crOpt
  mcOpt    = mcOpt_fcr ( crOpt );
  mfOpt    = mfOpt_fcr ( crOpt );
  TobsOpt  = TobsOpt_fcr ( crOpt );
  NsegOpt  = NsegOpt_fcr ( crOpt );

  ## package this into return-struct 'stackparams'
  stackparams.mCoh      = mcOpt;
  stackparams.mInc      = mfOpt;
  stackparams.Nseg      = NsegOpt;
  stackparams.Tseg      = TobsOpt / NsegOpt;
  stackparams.cr        = crOpt;

  return;

endfunction

%!test
%!  ## check recovery of published results in Prix&Shaltev(2012): V.A: directed CasA
%!  coefCoh.nDim = 2;
%!  coefCoh.delta = 4.00;
%!  coefCoh.kappa = 3.1358511e-17;
%!  coefCoh.lattice = "Ans";
%!  coefCoh.xi = meanOfHist ( LatticeMismatchHist ( coefCoh.nDim, coefCoh.lattice ) );
%!
%!  coefInc.nDim = 3;
%!  coefInc.delta = 6.0;
%!  coefInc.eta = 4;
%!  coefInc.kappa = 2.38382054e-33;
%!  coefInc.lattice = "Ans";
%!  coefInc.xi = meanOfHist ( LatticeMismatchHist ( coefInc.nDim, coefInc.lattice ) );
%!
%!  constraints.cost0 = 471.981444 * 86400;
%!  stackparams = LocalSolution4StackSlide ( coefCoh, coefInc, constraints, w = 1 );
%!  assert ( stackparams.cr, 1, 1e-6 );                 ## Eq.(117)
%!  assert ( stackparams.mCoh, 0.180879057028436, 1e-6 );               ## Eq.(118), corrected for xi_c from "Ans(2)" instead of 0.5
%!  assert ( stackparams.mInc, 0.271318585542655, 1e-6 );               ## Eq.(118), corrected for xi_f  from "Ans(3)" instead of 0.5
%!  assert ( stackparams.Tseg / 86400, 2.4178, 1e-3 );  ## corrected result, found in Shaltev thesis, Eq.(4.119), corrected for accurate xi_c, xi_f
%!  assert ( stackparams.Nseg, 61.7557, 1e-4 );         ## corrected result, found in Shaltev thesis, Eq.(4.119), corrected for accurate xi_c, xi_f

%!test
%!  ## check recovery of published results in Prix&Shaltev(2012): V.B: all-sky E@H [S5GC1], TableII
%!  coefCoh.nDim = 4;
%!  coefCoh.delta = 10.0111962295912;
%!  coefCoh.kappa = 9.09857109479269e-50;
%!  coefCoh.lattice = "Zn";
%!  coefCoh.xi = meanOfHist ( LatticeMismatchHist ( coefCoh.nDim, coefCoh.lattice ) );
%!
%!  coefInc.nDim = 4;
%!  coefInc.delta = 9.01119622959135;
%!  coefInc.eta = 2;
%!  coefInc.kappa = 1.56944271959491e-47;
%!  coefInc.lattice = "Zn";
%!  coefInc.xi = meanOfHist ( LatticeMismatchHist ( coefInc.nDim, coefInc.lattice ) );
%!
%!  constraints.cost0 = 3258.42235987226;
%!  constraints.Tobs0 = 365*86400;
%!  pFA = 1e-10; pFD = 0.1;
%!  NsegRef = 527.6679900489286;
%!  w = SensitivityScalingDeviationN ( pFA, pFD, NsegRef );
%!  assert ( w, 1.09110248396901, 1e-6 );
%!  stackparams = LocalSolution4StackSlide ( coefCoh, coefInc, constraints, w );
%!  assert ( stackparams.cr, 0.869163870996078, 1e-4 );
%!  assert ( stackparams.mCoh, 0.144345898957936, 1e-4 );
%!  assert ( stackparams.mInc, 0.1660744351839173, 1e-4 );
%!  assert ( stackparams.Tseg, 59764.8513746905, -1e-4 );
%!  assert ( stackparams.Nseg, NsegRef, -1e-4 );
