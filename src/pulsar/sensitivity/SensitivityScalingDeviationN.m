%% w = SensivitiyScalingDeviationN ( pFA, pFD, Nseg, approx = "none" )
%%
%% computes the relative deviation 'w' of the StackSlide sensitivity power-law scaling
%% coefficient from the weak-signal limit.
%% In the Gaussian weak-signal limit ("WSG"), the critical non-centrality RHO^2 scales exactly as
%% RHO^2 ~ N^(1/2), and threshold signal-strength hth therefore scales as ~ N^(-1/4)
%%
%% In general the N-scaling deviates from this, and we can locally describe it as a power-law
%% of the form RHO^2 ~ N^(1/(2w), and hth ~ N^(-1/(4w)), respecitvely, where 'w' quantifies
%% the relative devation from the WSG-scaling w=1.
%%
%% if 'approx' == "none" use full chi^2_(4*Nseg) distribution
%% if 'approx' == "Gauss" then use the Gaussian (N>>1) approximation
%% if 'approx' == "WSG": return w=1 for the "weak-signal Gaussian" case
%%
%% 'Nseg' is allowed to be a vector, in which case the return vector is w(Nseg)
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

function w = SensitivityScalingDeviationN ( pFA, pFD, Nseg, approx = "none" )

  if ( (length(pFA) != 1) || (length(pFD) != 1))
    error ("Sorry: can only deal with single input-values for 'pFA' and 'pFD'\n");
  endif

  %% ----- treat special 'WSG' case exactly first
  if ( strcmpi ( approx, "WSG" ) )
    w = ones ( size ( Nseg ) );
    return;
  endif

  %% ----- Gaussian or NO approximations
  fun_rhoS2 = @(Nseg0) log( CriticalNoncentralityStackSlide ( pFA, pFD, Nseg0, approx ) );

  deriv = Nseg .* gradient ( fun_rhoS2, Nseg, 0.01 );

  w = 1 ./ ( 2 * deriv);

endfunction
