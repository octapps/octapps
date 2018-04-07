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

## Usage: stackparams = LocalSolution4Fstat ( coefCoh, cost0, xi_or_latt = 1/3 )
## where options are:
## "coefCoh":          structure holding local power-law coefficients { delta, kappa, nDim } (and lattice)
##                    of coherent computing cost ~ mis^{-nDim/2} * Tseg^delta,
##                    where 'nDim' is the associated template-bank dimension
## "cost0":           computing cost constraint
##
## Compute the local solution for optimal F-statistic search parameters at given (local) power-law coefficients 'coefCoh',
## and given computing-cost constraint 'cost0'.
##
## NOTE: this solution is *not* guaranteed to be self-consistent, in the sense that the power-law coefficients
## at the point of this local solution may be different from the input 'coefCoh'
##
## Return structure 'stackparams' has fields {Nseg = 1, Tseg, mCoh, mInc=0, cr = inf }
## where Nseg is the number of segments (here =1 by definition), optimal coherent observation time Tseg,
## optimal coherent-grid mismatch mCoh, incoherent-grid mismatch mInc=0,
## and computing-cost ratio cr = CostCoh / CostIncoh (here = inf by definition).
##
## [Equation numbers refer to Prix&Shaltev, PRD85, 084010 (2012)]
##

function stackparams = LocalSolution4Fstat ( coefCoh, cost0 )

  ## check user-input sanity
  assert ( cost0 > 0 );
  assert ( isfield(coefCoh, "delta" ) );
  assert ( isfield(coefCoh, "kappa" ) );
  assert ( isfield(coefCoh, "nDim" ) );

  ## useful shortcuts
  deltac = coefCoh.delta;
  kappac = coefCoh.kappa;
  nc     = coefCoh.nDim;

  xi     = meanOfHist( LatticeMismatchHist( round(nc), coefCoh.lattice ) ); ## factor linking average and maximal mismatch for selected lattice

  mcOpt   = ( xi * ( 1 + 2 * deltac / nc ))^(-1);                       ## Eq.(69)
  TobsOpt = ( cost0 / kappac )^(1/deltac) * mcOpt^(nc/(2*deltac));      ## Eq.(70)

  stackparams.Tseg = TobsOpt;
  stackparams.Nseg = 1;
  stackparams.mCoh = mcOpt;
  stackparams.mInc = 0;
  stackparams.cr   = inf;

  return;

endfunction

%!test
%!  ## check recovery of published results in Prix&Shaltev(2012)
%!  coefCoh.delta = 7; coefCoh.nDim = 3; coefCoh.lattice = "Ans";
%!  coefCoh.kappa = 2.83216623e-36;
%!  cost0 = 471.981444 * 86400;
%!  stackparamsCoh = LocalSolution4Fstat ( coefCoh, cost0 );
%!  assert ( stackparamsCoh.Tseg / 86400, 13.7030102012432, 1e-6 );
%!  assert ( stackparamsCoh.mCoh, 0.371528463689787, 1e-6 );
