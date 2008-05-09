%% loadCandidateFile ( fname )
%%
%% loads a 'candidate-file' from ComputeFStatistic_v2 --outputLoudest=cand.file
%% and returns a struct containing the data
%%

%%
%% Copyright (C) 2006 Reinhard Prix
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

function ret = loadCandidateFile ( fname )
  source ( fname );	%% uses only local variables!

  %% amplitude params with error-estimates
  ret.phi0    = phi0;
  ret.dphi0   = dphi0;
  ret.psi     = psi;
  ret.dpsi    = dpsi;
  ret.h0      = h0;
  ret.dh0     = dh0;
  ret.cosi    = cosi;
  ret.dcosi   = dcosi;

  %% Doppler params
  ret.Alpha   = Alpha;
  ret.Delta   = Delta;
  ret.refTime = refTime;
  ret.Freq    = Freq;
  ret.f1dot   = f1dot;
  ret.f2dot   = f2dot;
  ret.f3dot   = f3dot;

  %% Antenna-pattern matrix M_mu_nu:
  ret.Ad       =  Ad;
  ret.Bd       =  Bd;
  ret.Cd       =  Cd;
  ret.Sinv_Tsft=  Sinv_Tsft;

  %% Fstat-results
  ret.Fa      = Fa;
  ret.Fb      = Fb;
  ret.twoF    = twoF;

endfunction
