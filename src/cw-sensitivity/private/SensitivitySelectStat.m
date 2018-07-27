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

function [calcPdet, calcPDF] = SensitivitySelectStat(varargin)

  ## options
  uvar = parseOptions(varargin,
	       {"Nseg", "integer,strictpos,vector"},
	       {"stat", "char","ChiSqr"},
               {"pval", "real,strictunit,matrix", []},
               {"stat_th", "real,strictpos,matrix",[]},
	       {"perSeg_th","real,positive,matrix",0},
	       {"dof", "integer,strictpos,scalar",4},
	       {"mism_w", "real",1} # multi-dimensional array != matrix, vector
	      );
  Nseg = uvar.Nseg;
  stat = uvar.stat;
  pval = uvar.pval;
  stat_th = uvar.stat_th;
  perSeg_th = uvar.perSeg_th;
  dof = uvar.dof;
  mism_w = uvar.mism_w;

  
  ## check if p-value or threshold is given
  if !xor(isempty(pval), isempty(stat_th))
    error("%s: 'pval' and 'stat_th' are mutually exclusive options", funcName);
  endif
  ## make inputs common size and convert p-value to threshold
  if !isempty(pval)
    ## if pval is given convert to stat_th
    [cserr, pval,  Nseg, perSeg_th] = common_size(pval,  Nseg, perSeg_th);
    if cserr > 0
      error("%s: pval and Nseg are not of common size", funcName);
    endif
    switch stat
      case "ChiSqr"
	stat_th = invFalseAlarm_chi2(pval, Nseg.*4);
	calcPdet = @(rhosqr_eff) StackSlide_cdf(Nseg, rhosqr_eff, mism_w,stat_th);
	calcPDF = @(rhosqr_eff) StackSlide_pdf(Nseg, rhosqr_eff, mism_w,stat_th);
      case "HoughFstat"
	STAT_TH = @(pval, Nseg) invFalseAlarm_HoughF(pval, Nseg, Fth);
	stat_th = arrayfun(STAT_TH, pval, Nseg);
	
	calcPdet = @(rhosqr_eff) HoughF_cdf(Nseg, rhosqr_eff, mism_w, stat_th, perSeg_th)
	calcPDF = @(rhosqr_eff) HoughF_pdf(Nseg, rhosqr_eff, mism_w, stat_th, perSeg_th)
      otherwise
	error("%s: invalid detection statistic '%s'", funcName, stat{1});
    endswitch
  else
    ## if stat_th is given just proceed
    [cserr, stat_th, Nseg, perSeg_th] = common_size(stat_th, Nseg, perSeg_th);
    if cserr > 0
      error("%s: stat_th  and Nseg are not of common size", funcName);
    endif
    switch stat
      case "ChiSqr"
	calcPdet = @(rhosqr_eff) StackSlide_cdf(Nseg, rhosqr_eff, mism_w,stat_th);
	calcPDF = @(rhosqr_eff) StackSlide_pdf(Nseg, rhosqr_eff, mism_w,stat_th);
      case "HoughFstat"
	calcPdet = @(rhosqr_eff) HoughF_cdf(Nseg, rhosqr_eff, mism_w, stat_th, perSeg_th)
	calcPDF = @(rhosqr_eff) HoughF_pdf(Nseg, rhosqr_eff, mism_w, stat_th, perSeg_th)
      otherwise
	error("%s: invalid detection statistic '%s'", funcName, stat{1});
    endswitch
  endif
  
endfunction

## Calculate Pdet(h_0, R^2) for the StackSlide method
function Pdet = StackSlide_cdf(Nseg, rhosqr_eff, mism_w, stat_th )

  ## degrees of freedom
  dof = 4.*Nseg;
  
  ## calculate pdf from chisquare
  cdf = ChiSquare_cdf(stat_th , dof, rhosqr_eff);

  ## integrate over mismatch
  
  Pdet= 1 - sum(cdf.*mism_w,5);
  
endfunction
    
## Calculate P(2F|h_0, R^2) for the StackSlide method
function PDF = StackSlide_pdf(Nseg, rhosqr_eff, mism_w, stat_th )

  ## degrees of freedom
  dof = 4.*Nseg;
  
  ## calculate pdf from chisquare
  pdf = ChiSquare_pdf(stat_th , dof, rhosqr_eff);

  ## integrate over mismatch
  
  PDF = sum(pdf.*mism_w,5);
  
endfunction

##  Calculate Pdet(h_0, R^2) for the HoughF method
function Pdet = HoughF_cdf(Nseg, rhosqr_eff, mism_w, stat_th, perSeg_th)

  ## calculate per segment cdf from chisquare
  perSeg_cdf = ChiSquare_cdf(perSeg_th, 4, rhosqr_eff);

  ## integrate over mismatch to get threshold crossing probability
  p_th = sum(perSeg_cdf.*mism_w,5);

  ## calculate binomial expression
  ## dimensions not correct
  nc = [0:stat_th];

  pdf_h0R2 = 1./(Nseg+1).*binomialRatePDF(p_th,Nseg,nc);

  ## integrate over numbercount
  Pdet = 1 - sum(pdf_h0R2)
 
  
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
