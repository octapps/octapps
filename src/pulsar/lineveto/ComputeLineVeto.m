## Copyright (C) 2012 David Keitel
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


function LVstat = ComputeLineVeto ( twoF_multi, twoF_single, rho, lX, useAllTerms )
  ## LVstat = compute_lv_lallike ( twoF_multi, twoF_single, rho, lX, useAllTerms )
  ## function to calculate Line Veto statistics for N detectors
  ## NOTE: input should be 2F, NOT F! Summed, not averaged, over segments!
  ## NOTE2: rho is therefore reinterpreted as "semicoherent rho", including Nseg exponent
  ## NOTE2: return value LVstat therefore still has to be divided  by Nseg to get output comparable to HSGCT
  ## original formula: LVstat = fstat_multi - log( rho_max_line^4/70 + exp(fstat1)*prior1 + exp(fstat2)*prior2 );
  ## implementation here is optimized to avoid underflows ("logsumexp formula")
  ## code is very close to implementation in lalapps/GCT/LineVeto.c

  # check for consistent vector/matrix lengths
  numcands = length(twoF_multi);
  numdets  = length(twoF_single(1,:));
  if ( length(twoF_single(:,1)) != numcands )
   error(["Invalid input - number of candidates does not match between twoF_multi (", int2str(numcands), " elements) and twoF_single (", int2str(length(twoF_single(:,1))), " rows)."]);
  endif
  if ( length(lX) != numdets )
   error(["Invalid input - number of detectors does not match between twoF_single (", int2str(numdets), " columns) and lX (", int2str(length(lX)), " elements)."]);
  endif

  # special treatment for additional denominator term 'rho^4/70'  - octave seems to work fine with log(0)=-inf
  if ( rho < 0.0 )
   error("Invalid input - prior parameter rho must be >=0.\n")
  else
    logRhoTerm = 4.0 * log(rho) - log(70.0);
    maxSumInit = logRhoTerm;
  endif

  # log the lX priors - octave seems to work fine with log(0)=-inf
  for X = 1:1:numdets
   if ( lX(X) < 0.0 )
    error("Invalid input - prior parameter lX must be >=0.\n")
   else
    loglX(X) = log(lX(X));
   endif
  endfor

  for n = 1:1:numcands

   maxInSum = maxSumInit;

   for X = 1:1:numdets # FXprior equiv log(lX * e^(FX)) = FX + log(lX)
    FXprior(n,X) = 0.5 * twoF_single(n,X);
    FXprior(n,X) += loglX(X);

    # keep track of maximum value in denominator sum 
    if ( FXprior(n,X) > maxInSum )
     maxInSum = FXprior(n,X);
    endif
   endfor # X < nDet

   LV = 0.5 * twoF_multi(n) - maxInSum; # dominant term to LV-statistic

   if ( useAllTerms == 1 )	# optionally add logsumexp term (possibly negligible in many cases)
    extraSum = 0;	# will be:  e^[-(maxInSum - logRhoTerm)] + sum_X e^[ -(maxInSum - FXprior) ] >= 1

    # need to treat (rho^4/70) term separately
    if ( rho > 0.0 )
     extraSum += exp ( logRhoTerm - maxInSum );
    endif
    # now add all FX-contributions
    for X = 1:1:numdets
     extraSum += exp (  FXprior(n,X) - maxInSum );
    endfor

    LV -= log( extraSum );

   endif # useAllTerms?

  LVstat(n) = LV;

  endfor # n < length(F)

endfunction # compute_lv_lallike()