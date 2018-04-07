## Copyright (C) 2011 Karl Wette
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

function [pd, Ns, FDP, fdp_vars, fdp_opts] = SensitivityChiSqrFDP(pd, Ns, args)

  FDP = @ChiSqrFDP;

  ## options
  parseOptions(args,
               {"paNt", "real,strictunit,matrix", []},
               {"sa", "real,strictpos,matrix", []},
               {"dof", "real,strictpos,scalar", 4},
               {"norm", "logical,scalar", false}
              );
  fdp_opts.dof = dof;
  fdp_opts.norm = norm;

  ## false alarm threshold
  if !xor(isempty(paNt), isempty(sa))
    error("%s: 'paNt' and 'sa' are mutually exclusive options", funcName);
  endif
  if !isempty(paNt)
    [cserr, paNt, pd, Ns] = common_size(paNt, pd, Ns);
    if cserr > 0
      error("%s: paNt, pd, and Ns are not of common size", funcName);
    endif
    sa = invFalseAlarm_chi2(paNt, Ns.*dof);
  else
    [cserr, sa, pd, Ns] = common_size(sa, pd, Ns);
    if cserr > 0
      error("%s: sa, pd, and Ns are not of common size", funcName);
    endif
  endif

  ## variables
  fdp_vars{1} = sa;

endfunction

## calculate false dismissal probability
function pd_rhosqr = ChiSqrFDP(pd, Ns, rhosqr, fdp_vars, fdp_opts)

  ## degrees of freedom per segment
  nu = fdp_opts.dof;

  ## false alarm threshold
  sa = fdp_vars{1};

  ## false dismissal probability
  if fdp_opts.norm

    ## use normal approximation
    mean = Ns.*( nu + rhosqr );
    stdv = sqrt( 2.*Ns .* ( nu + 2.*rhosqr ) );
    pd_rhosqr = normcdf(sa, mean, stdv);

  else

    ## use non-central chi-sqr distribution
    pd_rhosqr = ChiSquare_cdf(sa, Ns*nu, Ns.*rhosqr);

  endif

endfunction
