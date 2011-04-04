%% Returns a normalized histogram representing a Gaussian pdf with given mean and standard deviation
%%
%% Syntax:
%%   hgrm = createGaussianHist (M, S, "key1", val1, ... )
%% where:
%%   hgrm = returned histogram struct
%%   M    = mean of the Gaussian distribution
%%   V    = standard deviation
%%
%%   optional allowed keywords are
%%   "err" = convergence requirement on histogram, default err = 1e-2
%%   "binsize"  = histogram bin-size, default binsize = 0.01
%%

%%
%%  Copyright (C) 2011 Reinhard Prix
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

function hgrm = createGaussianHist ( M, S, varargin )
  fn = "createGaussianHist()";

  %% check input arguments
  if ( !exist("M") || !exist("S") )
    error ("%s: Need to provide arguments mean 'M' and standard deviation 'S'\n", fn );
  endif
  if ( !isscalar(M) || !isscalar(S) )
    error ("%s: Input arguments for mean and standard deviation must be scalars!\n", fn );
  endif

  %% default bin-size is 10 bins per std-dev
  dx0 = S / 10.0;

  %% parse optional keywords, set defaults if not specified
  kv = keyWords ( varargin, "err", 1e-2, "binsize", dx0 );

  %% create 1D histogram struct
  hgrm = newHist ( 1 );

  %% iterate, adding N samples every round, and continue until histogram has converged
  %% to within the given tolerance of 'err'
  N = 1000;
  do
    %% generate values of ap, ax, Fp, and Fx
    newsamples = normrnd ( M, S, N, 1);	%% N-vector of Gaussian random draws

    %% add new values to histogram
    oldhgrm = hgrm;
    hgrm = addDataToHist ( hgrm, newsamples, kv.binsize );

    %% calculate difference between old and new histograms
    err = histMetric ( hgrm, oldhgrm );

    %% continue until error is small enough
    %% (exit after 1 iteration if all parameters are constant)
  until err < kv.err

  %% output final histogram
  hgrm = normaliseHist ( hgrm );

endfunction
