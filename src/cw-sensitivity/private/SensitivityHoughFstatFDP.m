## Copyright (C) 2011, 2012 Reinhard Prix, Karl Wette
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
## Calculate the false dismissal probability of the F-statistic, summed using
## the Hough method

function [pd, Ns, FDP, fdp_vars, fdp_opts] = SensitivityHoughFstatFDP(pd, Ns, args)

  FDP = @HoughFstatFDP;

  ## options
  parseOptions(args,
               {"paNt", "real,strictpos,matrix", []},
               {"nth", "real,strictpos,matrix", []},
               {"Fth", "real,strictpos,scalar"},
               {"zero", "logical,scalar", false}
              );
  fdp_opts.Fth = Fth;
  fdp_opts.zero = zero;

  ## false alarm probability per template, and number count false alarm threshold
  if !xor(isempty(paNt), isempty(nth))
    error("%s: 'paNt' and 'nth' are mutually exclusive options", funcName);
  endif
  if !isempty(paNt)
    [cserr, paNt, pd, Ns] = common_size(paNt, pd, Ns);
    if cserr > 0
      error("%s: paNt, pd, and Ns are not of common size", funcName);
    endif
    NTH = @(paNt, Ns) invFalseAlarm_HoughF(paNt, Ns, Fth);
    nth = arrayfun(NTH, paNt, Ns);
  else
    [cserr, nth, pd, Ns] = common_size(nth, pd, Ns);
    if cserr > 0
      error("%s: nth, pd, and Ns are not of common size", funcName);
    endif
    FAP = @(nth, Ns) falseAlarm_HoughF(nth, Ns, Fth);
    nth = arrayfun(FAP, nth, Ns);
  endif

  ## variables
  fdp_vars{1} = paNt;
  fdp_vars{2} = nth;

endfunction

## calculate false dismissal probability
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
