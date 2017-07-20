## Copyright (C) 2016 Christoph Dreissigacker
## Copyright (C) 2012 Reinhard Prix
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

## Estimate StackSlide sensitivity depth, defined as
##
## sensDepth = sqrt(Sdata)/h0,
##
## where 'Sdata' is an estimate of the noise PSD over all the data used
## (which should be computed as the harmonic mean over all the SFTs from
## all detectors), and 'h0' is the smallest detectable GW amplitude at the
## given false-alarm (pFA) and false-dismissal probability (pFD)
##
## Usage:
##   sensDepth = SensitivityDepthStackSlide("opt", val, ...)
## Options are:
##   "Nseg":            number of StackSlide segments (every row is one trial, every column is for one stage )
##   "Tdata":           total amount of data used, in seconds
##                      can be a row vector for different amounts of data in each stage
##                      or a column vector for different trial setups or matrix for both combined
##                      (Note: Tdata = Nsft * Tsft, where 'Nsft' is the total number of
##                      SFTs of length 'Tsft' used in the search, from all detectors)
##   "misHist":         cell array of mismatch histograms, one for every stage, produced using Hist()
##   "pFD":             false-dismissal probability = 1 - pDet = 1 - 'confidence'
##   "pFA":             false-alarm probability (-ies) *per template* (every row is one trial, every column is for one stage )
##   "avg2Fth"		ALTERNATIVE to pFA: average-2F threshold (every row is one trial, every column is for one stage )
##   "detectors":       CSV list of detectors to use ("H1"=Hanford, "L1"=Livingston, "V1"=Virgo, ...)
##   "detweights":      detector weights on S_h to use (default: uniform weights)
##   "alpha":           source right ascension in radians (default: all-sky)
##   "delta":           source declination (default: all-sky)
##
##  Example input:
##              Nseg = [90,90,44,44,22;100,100,50,50,25]                          two different setups with 5 stages (5 columns, 2 rows)
##              Tdata = [ NSFT*1800, NSFT*900, NSFT*3600, NSFT*1800, NSFT*1800]   different for every stage but the same for every trial
##              avg2Fth = [6.109,6.109,7.38,8.82,15]                              as we have 5 stages there must be five thresholds
##              misHist = {mismatch1, mismatch2, mismatch3, mismatch4, mismatch5} we also need one mismatch histogram per stage
##              pFD = [0.1,0.05]'                                                 a column with two false dimissal probabilitites, one for each trial
##
##
##


function sensDepth = SensitivityDepthStackSlide ( varargin )

  ## parse options
  uvar = parseOptions ( varargin,
		       {"Nseg", "integer,strictpos,matrix", 1 },
		       {"Tdata", "real,strictpos,matrix" },
		       {"misHist", "acell:Hist", []},
		       {"pFD", "real,strictpos,column", 0.1},
		       {"pFA", "real,strictpos,matrix", []},
		       {"avg2Fth", "real,strictpos,matrix", []},
		       {"detectors", "char", "H1,L1" },
		       {"detweights", "real,strictpos,vector", []},
		       {"alpha", "real,vector", [0, 2*pi]},
		       {"delta", "real,vector", [-pi/2, pi/2]},
		       []);

  ## check input
  assert ( ! ( isempty ( uvar.pFA ) && isempty ( uvar.avg2Fth ) ), "Need at least one of 'pFA' or 'avg2Fth' to determine false-alarm probability!\n" );
  assert ( isempty ( uvar.pFA ) || isempty ( uvar.avg2Fth ), "Must specify exactly one of 'pFA' or 'avg2Fth' to determine false-alarm probability!\n" );
  assert ( !isempty(uvar.Tdata), "Tdata must be specified.\n");
  assert ( isempty(uvar.misHist) ||(((size(uvar.pFA,2) == length(uvar.misHist)) || (size(uvar.avg2Fth,2) == length(uvar.misHist))) && size(uvar.Nseg,2) == length(uvar.misHist)) ,
	   "#stages unclear, #columns in pFA/avg2Fth and Nseg must match #mismatch histograms.\n");

  ## two different ways to specify false-alarm / threshold
  if ( !isempty ( uvar.pFA ) )
    FAarg = { "paNt", uvar.pFA };
  else
    FAarg = { "sa", uvar.Nseg .* uvar.avg2Fth };
  endif

  ## compute sensitivity SNR
  Rsqr = SqrSNRGeometricFactorHist("detectors", uvar.detectors, "detweights", uvar.detweights, "alpha", uvar.alpha, "sdelta", sin(uvar.delta) );
  [sensDepth, pd_Depth] = SensitivityDepth ( "pd", uvar.pFD, "Ns", uvar.Nseg, "Tdata",uvar.Tdata, "Rsqr", Rsqr,"misHist",uvar.misHist, "stat", {"ChiSqr", FAarg{:}} );


endfunction

## compare with simulated perfect match depth for S5GC1HF
%!test
%!  Nseg = 205;
%!  Tdata = 17797*1800;
%!  pFD = 0.1;
%!  avg2Fth = sort([24.27;20.87;18.11;16.01;14.34;13.04;11.93;11.04;10.27;9.61;9.06]); #from simulation  for S5GC1HF
%!  dets = "H1,L1";
%!  depth = SensitivityDepthStackSlide("Nseg", Nseg, "Tdata", Tdata, "pFD", pFD, "avg2Fth", avg2Fth, "detectors", dets);
%!  measDepth = [40:-2:20]';
%!  assert(max(1./measDepth.*(abs(depth - measDepth))) < 0.02);

## some basic examples to test functionality
%!test
%!  Nseg = [90,90,44,44,22;100,100,50,50,25];
%!  NSFT = 17797;
%!  Tdata = [ NSFT*1800, NSFT*900, NSFT*3600, NSFT*1800, NSFT*1800];
%!  misHist = createDeltaHist(0.1);
%!  pFD = [0.1,0.05]';
%!  avg2Fth = [6.109,6.109,7.38,8.82,15];
%!  misHist = {createDeltaHist(0.5), createDeltaHist(0.4), createDeltaHist(0.3), createDeltaHist(0.2), createDeltaHist(0.1)};
%!  dets = "H1,L1";
%!  depth = SensitivityDepthStackSlide("Nseg", Nseg, "Tdata", Tdata, "misHist", misHist, "pFD", pFD, "avg2Fth", avg2Fth, "detectors", dets);
%!  assert(max(abs(depth - [50.855; 44.681])) < 0.01);
%!test
%!  Nseg = 20;
%!  Tdata = 60*3600*Nseg;
%!  misHist = createDeltaHist(0.1);
%!  pFD = 0.1;
%!  pFA = [1e-14; 1e-12; 1e-10];
%!  dets = "H1,L1";
%!  depth = SensitivityDepthStackSlide("Nseg", Nseg, "Tdata", Tdata, "misHist", misHist, "pFD", pFD, "pFA", pFA, "detectors", dets);
%!  assert(max(abs(depth - [37.950; 40.007; 42.555])) < 0.01);
%!test
%!  Nseg = 205;
%!  Tdata = 17797*1800;
%!  pFD = 0.1;
%!  misHist = createGaussianHist(0.3,0.05);
%!  pFA = [1e-14; 1e-12; 1e-10; 1e-9];
%!  dets = "H1,L1";
%!  depth = SensitivityDepthStackSlide("Nseg", Nseg, "Tdata", Tdata, "misHist", misHist, "pFD", pFD, "pFA", pFA, "detectors", dets);
%!  assert(max(abs(depth - [57.537; 60.193; 63.487; 65.471])) < 0.01);
