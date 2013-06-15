%% Returns a normalized histogram representing a Gaussian pdf with given mean and standard deviation
%%
%% Syntax:
%%   hgrm = createGaussianHist (M, S, "key1", val1, ... )
%% where:
%%   hgrm = returned histogram class
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

  %% check input arguments
  if ( !exist("M") || !exist("S") )
    error ("%s: Need to provide arguments mean 'M' and standard deviation 'S'\n", funcName );
  endif
  if ( !isscalar(M) || !isscalar(S) )
    error ("%s: Input arguments for mean and standard deviation must be scalars!\n", funcName );
  endif

  %% parse optional keywords
  parseOptions(varargin,
               {"err", "numeric,scalar", 1e-2},
               {"binsize", "numeric,scalar", S / 10.0});

  %% create 1D histogram class
  hgrm = Hist( 1, {"lin", "dbin", binsize} );

  %% iterate, adding N samples every round, and continue until histogram has converged
  %% to within the given tolerance of 'err'
  N = 1e6;
  do
    %% generate values of ap, ax, Fp, and Fx
    newsamples = normrnd ( M, S, N, 1);	%% N-vector of Gaussian random draws

    %% add new values to histogram
    oldhgrm = hgrm;
    hgrm = addDataToHist ( hgrm, newsamples );

    %% calculate difference between old and new histograms
    histerr = histDistance ( hgrm, oldhgrm );

    %% continue until error is small enough
    %% (exit after 1 iteration if all parameters are constant)
  until histerr < err

endfunction


## generate Gaussian histogram and check its properties
%!test
%! hgrm = createGaussianHist(1.2, 3.4, "err", 1e-2, "binsize", 0.1);
%! assert(abs(meanOfHist(hgrm) - 1.2) < 0.1)
%! assert(abs(sqrt(varianceOfHist(hgrm)) - 3.4) < 0.1)
