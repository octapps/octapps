%% noncent1 = Chi2CriticalNoncentrality ( pFA, pFD, dof, [noncent0 = 9] )
%%
%% function to compute the 'critical' non-centrality parameter required to obtain
%% exactly pFD false-dismissal probability at given pFA false-alarm
%% probability for a chi^2 distribution with 'dof' degrees of freedrom,
%% i.e. the solution 'noncent1' to the equations
%%
%% pFA = prob ( S > Sth | noncent=0 )
%% pFD = prob ( S < Sth | noncent=noncent1 )
%%
%% at given {pFA, pFD}, and S ~ chi^2_dof ( noncent ) is chi^2-distributed with 'dof'
%% degrees of freedrom and non-centrality 'noncent'.
%%
%% The optional argument 'noncent0' allows to specify a starting trial value.
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

function noncent1 = Chi2CriticalNoncentrality ( pFA, pFD, dof, noncent0 = 3 )

  %% first get F-stat threshold corresponding to pFA false-alarm probability
  Sth = invFalseAlarm_chi2 ( pFA, dof );

  %% numerically solve equation pFD = chi2_dof ( Sth; noncent )
  fun = @(noncent) ChiSquare_cdf( Sth, dof, noncent) - pFD;

  [noncent1, fun1, INFO, OUTPUT] = fzero (fun, noncent0);

  if ( INFO != 1 || noncent1 <= 0 )
    error ("fzero() failed to converge for pFA=%g, pFD=%g and trial value rho0 = %g: rho1 = %g, fun1 = %g\n", pFA, pFD, noncent0, noncent1, run1 );
  endif

  return;

endfunction

