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

## Usage: stackparams = LocalSolution4Fstat ( coef_c, cost0, xi_or_latt = 1/3 )
## where options are:
## "coef_c":          structure holding local power-law coefficients { delta, kappa, nDim }
##                    of coherent computing cost ~ mis^{-nDim/2} * Tseg^delta,
##                    where 'nDim' is the associated template-bank dimension
## "cost0":           computing cost constraint
##
## "xi_or_latt":      [optional] EITHER: average mismatch-factor 'xi' linking average and maximal mismatch: <m> = xi * mis_max
##                    OR: string giving lattice type to use (e.g. "Zn", "Ans"), from which 'xi' is computed 
##                    [default = 1/3 for hypercubic lattice]
##
## Compute the local solution for optimal F-statistic search parameters at given (local) power-law coefficients 'coef_c',
## and given computing-cost constraint 'cost0', and (optional) average-mismatch geometrical factor 'xi' in [0,1] or lattice string.
##
## NOTE: this solution is *not* guaranteed to be self-consistent, in the sense that the power-law coefficients
## at the point of this local solution may be different from the input 'coef_c'
##
## Return structure 'stackparams' has fields {Nseg = 1, Tseg, mc, mf=0, cr = inf }
## where Nseg is the number of segments (here =1 by definition), optimal coherent observation time Tseg,
## optimal coarse-grid mismatch mc, fine-grid mismatch mf=0,
## and computing-cost ratio cr = CostCoh / CostIncoh (here = inf by definition).
##
## [Equation numbers refer to Prix&Shaltev, PRD85, 084010 (2012)]
##

function stackparams = LocalSolution4Fstat ( coef_c, cost0, xi_or_latt = 1/3 )

  ## check user-input sanity
  assert ( cost0 > 0 );
  assert ( isfield(coef_c, "delta" ) );
  assert ( isfield(coef_c, "kappa" ) );
  assert ( isfield(coef_c, "nDim" ) );

  %% useful shortcuts
  deltac = coef_c.delta;
  kappac = coef_c.kappa;
  nc     = coef_c.nDim;

  %% ----- average mismatch factor linking average and maximal mismatch for selected lattice
  if ( ischar ( xi_or_latt ) )
    xi = meanOfHist( LatticeMismatchHist( round(nc), xi_or_latt ) );
  elseif ( isnumeric ( xi_or_latt ) )
    xi = xi_or_latt;
  else
    error( "Invalid value given for 'xi_or_latt'" )
  endif

  mcOpt   = ( xi * ( 1 + 2 * deltac / nc ))^(-1);			## Eq.(69)
  TobsOpt = ( cost0 / kappac )^(1/deltac) * mcOpt^(nc/(2*deltac));	## Eq.(70)

  stackparams.Tseg = TobsOpt;
  stackparams.Nseg = 1;
  stackparams.mc   = mcOpt;
  stackparams.mf   = 0;
  stackparams.cr   = inf;

  return;

endfunction

%!test
%!  %% check recovery of published results in Prix&Shaltev(2012)
%!  coef_c.delta = 7; coef_c.nDim = 3;
%!  coef_c.kappa = 2.83216623e-36;
%!  xi = 0.5; cost0 = 471.981444 * 86400;
%!  stackparamsCoh = LocalSolution4Fstat ( coef_c, cost0, xi );
%!  assert ( stackparamsCoh.Tseg / 86400, 13.55313, 1e-6 );
%!  assert ( stackparamsCoh.mc, 0.352941176, 1e-6 );
