## Copyright (C) 2018 Christoph Dreissigacker
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

## Helper function for SensitivityDepth()
##
## Calculate the false dismissal probability of a chi^2 detection statistic,
## such as the F-statistic

function [calcPh0R2, stat_th, perSeg_th] = SensitivitySelectStat(Nseg, Bayesian, stat)

  ## options
  parseOptions(stat{2:end},
               {"pval", "real,strictunit,matrix", []},
               {"stat_th", "real,strictpos,matrix", []},
	       {"perSeg_th","real,strictpos,matrix",0},
              );
  ## check if p-value or threshold is given
  if !xor(isempty(pval), isempty(stat_th))
    error("%s: 'pval' and 'stat_th' are mutually exclusive options", funcName);
  endif
  ## make inputs common size and convert p-value to threshold
  if !isempty(pval)
    [cserr, pval,  Nseg, perSeg_th] = common_size(pval,  Nseg, perSeg_th);
    if cserr > 0
      error("%s: pval and Nseg are not of common size", funcName);
    endif
    switch stat{1}
      case "ChiSqr"
	stat_th = invFalseAlarm_chi2(pval, Nseg.*4);
	if !Bayesian
	  calcPh0R2 = @StackSlide_cdf
	else
	  calcPh0R2 = @StackSlide_pdf
	endif
      case "HoughFstat"
	STAT_TH = @(pval, Nseg) invFalseAlarm_HoughF(pval, Nseg, Fth);
	stat_th = arrayfun(STAT_TH, pval, Nseg);
	if !Bayesian
	  calcPh0R2 = @HoughF_cdf
	else
	  calcPh0R2 = @HoughF_pdf
	endif
      otherwise
	error("%s: invalid detection statistic '%s'", funcName, stat{1});
    endswitch
  else
    [cserr, stat_th, Nseg, perSeg_th] = common_size(stat_th, Nseg, perSeg_th);
    if cserr > 0
      error("%s: stat_th  and Nseg are not of common size", funcName);
    endif
  endif
  
endfunction

## Calculate Pdet(h_0, R^2) for the StackSlide method
function P_h0R2 = StackSlide_cdf(Nseg, rhosqr_eff, mism_w, stat_th , perSeg_th =[] )

  ## degrees of freedom
  dof = 4.*Nseg;
  
  ## calculate pdf from chisquare
  cdf = ChiSquare_cdf(stat_th , dof, Nseg.*rhosqr_eff);

  ## integrate over mismatch
  
  Pstat_h0R2 = sum(cdf.*mism_w,5);
  
endfunction
    
## Calculate P(2F|h_0, R^2) for the StackSlide method
function P_h0R2 = StackSlide_pdf(Nseg, rhosqr_eff, mism_w, stat_th , perSeg_th =[] )

  ## degrees of freedom
  dof = 4.*Nseg;
  
  ## calculate pdf from chisquare
  pdf = ChiSquare_pdf(stat_th , dof, Nseg.*rhosqr_eff);

  ## integrate over mismatch
  
  Pstat_h0R2 = sum(pdf.*mism_w,5);
  
endfunction

##  Calculate Pdet(h_0, R^2) for the HoughF method
function P_h0R2 = HoughF_cdf(Nseg, rhosqr_eff, mism_w, stat_th, perSeg_th)

  ## calculate per segment cdf from chisquare
  perSeg_cdf = ChiSquare_cdf(perSeg_th, 4, rhosqr_eff);

  ## integrate over mismatch to get threshold crossing probability
  p_th = sum(perSeg_cdf.*mism_w,5);

  ## calculate binomial expression
  nc = [0:stat_th].*ones(size(p_th));
  pdf_h0R2 = 1./(Nseg+1).*binomialRatePDF(p_th,Nseg,nc);

  ## integrate over numbercount
  P_h0R2 = sum(pdf_h0R2,
 
  
endfunction

##  Calculate P(2F|h_0, R^2) for the HoughF method
function P_h0R2 = HoughF_pdf(Nseg, rhosqr_eff, mism_w, stat_th, perSeg_th)

  ## calculate per segment cdf from chisquare
  perSeg_cdf = ChiSquare_cdf(perSeg_th, 4, rhosqr_eff);

  ## integrate over mismatch to get threshold crossing probability
  p_th = sum(perSeg_cdf.*mism_w,5);

  ## calculate binomial expression
  Pstat_h0R2 = 1./(Nseg+1).*binomialRatePDF(p_th,Nseg,stat_val);
  
endfunction
    
function pd_rhosqr = HoughFstatFDP(pd, Ns, rhosqr, fdp_vars, fdp_opts)

  ## F-statistic threshold per segment
  Fth = fdp_opts.Fth;

  ## false alarm probability per template, and number count false alarm threshold
  paNt = fdp_vars{1};
  nth = fdp_vars{2};

  ## false dismissal probability
  if fdp_opts.zero

    ## calculate the false dismissal probability using the
    ## zeroth-order approximation for the Hough-on-Fstat statistic
    ## valid in the limit of N>>1 and rho<<1
    ## this is based on Eq.(6.39) in KrishnanEtAl2004 Hough paper
    alpha = falseAlarm_chi2 ( 2*Fth, 4 );
    sa = erfcinv_asym(2*paNt);
    ## Theta from Eq.(5.28) in Hough paper, dropping second term in "large N limit" (s Eq.(6.40))
    Theta = sqrt ( Ns ./ ( 2*alpha.*(1-alpha)) );  ## + (1 - 2*alpha)./(1-alpha) .* (sa ./(2*alpha))
    pd_rhosqr = 0.5 * erfc ( - sa + 0.25 * Theta .* exp(-Fth) .* Fth.^2 .* rhosqr );

  else

    ## calculate the false dismissal probability using the
    ## exact distribution for the Hough-on-Fstat statistic
    FDP = @(nth, Ns, rhosqr) falseDismissal_HoughF(nth, Ns, Fth, rhosqr);
    pd_rhosqr = arrayfun(FDP, nth, Ns, rhosqr);

  endif

endfunction
