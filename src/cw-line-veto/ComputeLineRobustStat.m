## Copyright (C) 2012, 2014 David Keitel
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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{LRstat} =} ComputeLineRobustStat ( @var{twoF_multi}, @var{twoF_single}, @var{Fstar0}, @var{oLGX}, @var{useAllTerms} )
##
## function to calculate line-robust statistic for multiple detectors
##
## this is actually the log-Bayes-factor:
##
## LRstat = log10(B_@{SGL@}) = log10(O_@{SGL@})-log10(o_@{SGL@})
##
## see Eq. (36) of Keitel, Prix, Papa, Leaci, Siddiqi, PR D 89, 064023 (2014)
## and Eq. (55) for the semicoherent case
##
## @heading Notes
##
## @enumerate
##
## @item
## input should be 2F, NOT F! Summed, not averaged, over segments!
##
## @item
## Fstar0 is therefore reinterpreted as "semicoherent rho", Nseg exponent must already be included from caller
## (compare Eq. (57), Fstar0^=ln(cstar^Nseg) )
##
## @item
## pure line-veto statistic log10(BSL) is obtained in the limit Fstar0 -> -Inf
##
## @end enumerate
##
## @heading Original formula
##
## log10(B_SGL) = log10(e) * ( F_multi - log( (1-pL)*exp(Fstar0) + pL*<rX*exp(FX)> ) )
## = log10(e) * ( F_multi - log( (1-pL)*exp(Fstar0) + (pL/Ndet)*sum(rX*exp(FX)) ) )
##
## with
## @itemize
## @item line-to-Gauss prior odds oLG = sumX oLGX
## @item line prior weights       rX = oLGX*Ndet/oLG
## @item detector-average         <QX> = (1/Ndet) * sumX QX
## @item total line probability   pL = oLG/(1+oLG)
## @end itemize
##
## implementation here is optimized to avoid underflows ("log-sum-exp formula")
## should be compatible with current implementation in lalpulsar/src/LineRobustStats.c
##
## @end deftypefn

function LRstat = ComputeLineRobustStat ( twoF_multi, twoF_single, Fstar0, oLGX, useAllTerms )

  ## check for consistent vector/matrix lengths
  if ( isempty(twoF_multi) || isempty(twoF_single) || isempty(Fstar0) || isempty(oLGX) )
    error("Need non-empty input on all arguments!");
  endif
  numcands = length(twoF_multi);
  numdets  = length(twoF_single(1,:));
  if ( length(twoF_single(:,1)) != numcands )
    error(["Invalid input - number of candidates does not match between twoF_multi (", int2str(numcands), " elements) and twoF_single (", int2str(length(twoF_single(:,1))), " rows)."]);
  endif
  if ( length(oLGX) != numdets )
    error(["Invalid input - number of detectors does not match between twoF_single (", int2str(numdets), " columns) and oLGX (", int2str(length(oLGX)), " elements)."]);
  endif
  if ( any(oLGX < 0.0 ) )
    error("Invalid input - prior parameter oLGX must be >=0.")
  endif

  ## translate line priors
  oLG = sum(oLGX);
  rX = oLGX*numdets/oLG;
  pL = oLG/(1+oLG);

  ## special treatment for additional denominator term (1-pL)exp(F*0)  - octave seems to work fine with log(0)=-inf
  logFstar0Term = Fstar0 + log(1-pL);
  denomterms      = zeros(numcands,1+numdets); ## pre-allocate with fixed size, for minor speedup
  denomterms(:,1) = logFstar0Term*ones(numcands,1);

  ## get log per-detector terms
  for X = 1:1:numdets
    denomterms(:,1+X) = 0.5*twoF_single(:,X) + log(rX(X));
  endfor
  denomterms(:,2:end) += log(pL) - log(numdets);

  maxInSum = max( denomterms, [], 2 ); ## vector of the maximum from each row

  LRstat = 0.5 * twoF_multi - maxInSum; ## dominant term to LV-statistic

  if ( useAllTerms ) ## optionally add logsumexp term (possibly negligible in many cases)
    extraSum = zeros(numcands,1);
    for X = 1:1:length(denomterms(1,:))
      extraSum += exp ( denomterms(:,X) - maxInSum );
    endfor
    LRstat -= log( extraSum );
  endif ## useAllTerms?

  LRstat *= log10(e);

endfunction ## ComputeLineRobustStat()

%!assert(ComputeLineRobustStat(10, [6, 5], 0.1, [0.5, 0.5], false), 1.4706, 1e-3)
