%% noncent1 = CriticalNoncentralityStackSlide ( pFA, pFD, Nseg, [approx] )
%%
%% function to compute the 'critical' non-centrality parameter required to obtain
%% exactly pFD false-dismissal probability at given pFA false-alarm
%% probability for a chi^2 distribution with '4*Nseg' degrees of freedrom,
%% i.e. the solution 'noncent1' to the equations
%%
%% pFA = prob ( S > Sth | noncent=0 )
%% pFD = prob ( S < Sth | noncent )
%%
%% at given {pFA, pFD}, and S ~ chi^2_(4Nseg) ( noncent ) is chi^2-distributed with '4Nseg'
%% degrees of freedrom and non-centrality 'noncent'.
%%
%% the optional argument 'approx' allows one to control the level of approximation:
%% 'approx' == "none": use full chi^2_(4*Nseg) distribution, solve numerically
%% 'approx' == "Gauss": use Gaussian approximation, suitable for Nseg>>1, [analytic]
%% 'approx' == "WSG": weak-signal Gaussian approximation assuming rhoF<<1, [analytic]
%%

%%
%% Copyright (C) 2011 Reinhard Prix
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%

function noncent1 = CriticalNoncentralityStackSlide ( pFA, pFD, Nseg, approx = "none")

  alpha = erfcinv ( 2*pFA );
  beta  = erfcinv ( 2*pFD );

  if ( strcmpi ( approx, "none" ) )
    alevel = 0;
  elseif ( strcmpi ( approx, "Gauss" ) )
    alevel = 1;
  elseif ( strcmpi ( approx, "WSG" ) )
    alevel = 2;
  else
    error ("Input value 'approx' = '%s': allowed values are { \"none\", \"Gauss\" or \"WSG\" }\n", approx );
  endif

  %% ----- loop over input-vector values
  switch ( alevel )

      %% ----- no approximations, fully numerical solution
    case 0
      %% handle vector-input on 'Nseg'
      numVals  = length ( Nseg );
      noncent1 = zeros ( 1, numVals );
      for i = 1:numVals

        dof = 4 * Nseg(i);	%% degrees of freedom
        %% first get F-stat threshold corresponding to pFA false-alarm probability
        Sth = invFalseAlarm_chi2 ( pFA, dof );
        %% numerically solve equation pFD = chi2_dof ( Sth; noncent )
        fun = @(noncent) ChiSquare_cdf( Sth, dof, noncent) - pFD;
        x0 = 4*dof;	%% use '4dof' as starting-guess
        [noncent_i, fun1, INFO, OUTPUT] = fzero (fun, x0);
        if ( INFO != 1 || noncent_i <= 0 )
          OUTPUT
          error ("fzero() failed to converge for pFA=%g, pFD=%g, dof=%.1f and trial value rho0 = %g: rho1 = %g, fun1 = %g\n", pFA, pFD, dof, x0, noncent_i, fun1 );
        endif
        noncent1(i) = noncent_i;
      endfor ## loop over 'Nseg' vector

      %% ----- Gaussian approximation (suitable for N>>1), analytical
    case 1
      noncent1 = 4 * ( sqrt(Nseg) * alpha + beta^2 ) + 4 * beta * sqrt ( 2 *sqrt(Nseg) * alpha + beta^2 + Nseg );

      %% ----- weak-signal Gaussian approximation, analytical
    case 2
      noncent1 = 4 * sqrt(Nseg) * ( alpha + beta );

  endswitch

  return;

endfunction

