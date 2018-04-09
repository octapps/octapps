## Copyright (C) 2011 Reinhard Prix
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
## @deftypefn {Function File} {@var{noncent} =} CriticalNoncentralityStackSlide ( @var{pFA}, @var{pFD}, @var{Nseg}, @var{approx}= [ ] )
##
## function to compute the 'critical' non-centrality parameter required to obtain
## exactly @var{pFD} false-dismissal probability at given @var{pFA} false-alarm
## probability for a chi^2 distribution with '4*@var{Nseg} degrees of freedrom,
## i.e. the solution @var{noncent} to the equations
##
## @var{pFA} = prob ( S > Sth | @var{noncent}=0 ) --> Sth(@var{pFA})
## @var{pFD} = prob ( S < Sth(@var{pFA}) | @var{noncent} )
##
## at given @{@var{pFA}, @var{pFD}@}, and S ~ chi^2_(4Nseg) ( @var{noncent} ) is a chi^2-distributed statistic
## with '4Nseg' degrees of freedrom and non-centrality @var{noncent}.
##
## the optional argument @var{approx} allows to control the level of approximation:
## @itemize
## @item @code{approx} == "":
## use full chi^2_(4*@var{Nseg}) distribution
## @item @code{approx} == "Gauss":
## use the Gaussian (N>>1) approximation
## @item @code{approx} == "WSG":
## return w=1 for the "weak-signal Gaussian" case
## @end itemize
##
## @end deftypefn

function noncent = CriticalNoncentralityStackSlide ( pFA, pFD, Nseg, approx = [] )

  ## make sure pFa, pFD, Nseg are the same size
  [cserr, pFA, pFD, Nseg] = common_size ( pFA, pFD, Nseg );
  assert ( cserr == 0, "%s: pFA, pFD, and Nseg are not of common size", funcName );
  assert ( all ( isfinite(Nseg) ), "Nseg = %g must be finite\n", Nseg );
  assert ( all ( Nseg >= 1 ), "Nseg = %g must be >= 1\n", Nseg );

  alpha = erfcinv_asym ( 2*pFA );
  beta  = erfcinv_asym ( 2*pFD );

  if ( isempty ( approx ) )
    ## ----- no approximations, fully numerical solution

    dof = 4 * Nseg;     ## degrees of freedom
    ## first get F-stat threshold corresponding to pFA false-alarm probability
    Sth = invFalseAlarm_chi2 ( pFA, dof );

    ## ----- need to loop over zero-finding step explicitly
    noncent1 = zeros ( size(Nseg) );
    for i = 1:numel ( Nseg )

      ## numerically solve equation pFD = chi2_dof ( Sth; noncent )
      fun = @(noncent) ChiSquare_cdf( Sth(i), dof(i), noncent) - pFD(i);
      x0 = 4*dof(i);    ## use '4dof' as starting-guess
      [noncent_i, fun1, INFO, OUTPUT] = fzero (fun, x0);
      if ( INFO != 1 || noncent_i <= 0 )
        OUTPUT
        error ("fzero() failed to converge for pFA=%g, pFD=%g, dof=%.1f and trial value rho0 = %g: rho1 = %g, fun1 = %g\n", pFA(i), pFD(i), dof(i), x0, noncent_i, fun1 );
      endif

      noncent(i) = noncent_i;

    endfor ## loop over 'Nseg' vector

  elseif ( strcmpi ( approx, "Gauss" ) )
    ## ----- Gaussian approximation (suitable for N>>1), analytical
    noncent = 4 * ( sqrt(Nseg) .* alpha + beta.^2 ) + 4 * beta .* sqrt ( 2 *sqrt(Nseg) .* alpha + beta.^2 + Nseg );

  elseif ( strcmpi ( approx, "WSG" ) )
    ## ----- weak-signal Gaussian approximation, analytical
    noncent = 4 * sqrt(Nseg) .* ( alpha + beta );

  else
    error ("Invalid input 'approx' = '%s': allowed values are { [], \"Gauss\" or \"WSG\" }\n", approx );
  endif

  return;

endfunction

%!test
%!  ## compare with example cases in Prix&Shaltev,PRD85,084010(2012)
%!  pFA = 1e-10; pFD = 0.1;
%!  rhoF2 = CriticalNoncentralityStackSlide ( pFA, pFD, 1 );
%!  assert ( sqrt(rhoF2), 8.35, -1e-2 );
%!
%!  Nseg = 139; rhoS2 = CriticalNoncentralityStackSlide ( pFA, pFD, Nseg );
%!  assert ( sqrt(rhoS2), 17.3, -1e-2 );
