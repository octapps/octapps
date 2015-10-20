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

## Estimate Hough-on-Fstat sensitivity depth, defined as
##
## sensDepth = sqrt(Sdata)/h0,
##
## where 'Sdata' is an estimate of the noise PSD over all the data used
## (which should be computed as the harmonic mean over all the SFTs from
## all detectors), and 'h0' is the smallest detectable GW amplitude at the
## given false-alarm (pFA) and false-dismissal probability (pFD)
##
## Usage:
##   sensDepth = SensitivityDepthHoughF("opt", val, ...)
## Options are:
##   "Nseg":            number of Hough segments
##   "Tdata":           total amount of data used, in seconds
##                      (Note: Tdata = Nsft * Tsft, where 'Nsft' is the total number of
##                      SFTs of length 'Tsft' used in the search, from all detectors)
##   "misHist":         mismatch histogram, produced using Hist()
##   "pFD":             false-dismissal probability = 1 - pDet
##   "pFA":             false-alarm probability (-ies) *per template* (can be a vector)
##   "Fth":             F-stat threshold (on F, not 2F!) in each segment for "pixel" selection
##   "detectors":       CSV list of detectors to use ("H1"=Hanford, "L1"=Livingston, "V1"=Virgo, ...)
##   "detweights":      detector weights on S_h to use (default: uniform weights)
##   "alpha":           source right ascension in radians (default: all-sky)
##   "delta":           source declination (default: all-sky)

function sensDepth = SensitivityDepthHoughF ( varargin )

  ## parse options
  uvar = parseOptions ( varargin,
                       {"Nseg", "integer,strictpos,scalar", 1 },
                       {"Tdata", "real,strictpos,scalar" },
                       {"misHist", "Hist" },
                       {"pFD", "real,strictpos,scalar", 0.1},
                       {"pFA", "real,strictpos,vector"},
                       {"Fth", "real,strictpos,scalar", 5.2/2 },
                       {"detectors", "char", "H1,L1" },
                       {"detweights", "real,strictpos,vector", []},
                       {"alpha", "real,vector", [0, 2*pi]},
                       {"delta", "real,vector", [-pi/2, pi/2]},
                       []);

  ## compute sensitivity SNR
  Rsqr = SqrSNRGeometricFactorHist("detectors", uvar.detectors, "detweights", uvar.detweights, "mism_hgrm", uvar.misHist, "alpha", uvar.alpha, "sdelta", sin(uvar.delta) );
  rho = SensitivitySNR ( uvar.pFD, uvar.Nseg, Rsqr, "HoughFstat", "paNt", uvar.pFA, "Fth", uvar.Fth);

  ## convert to sensitivity depth
  TdataSeg = uvar.Tdata / uvar.Nseg;
  sensDepthInv = 5/2 .* rho .* TdataSeg.^(-1/2);
  sensDepth = 1 ./ sensDepthInv;

endfunction


## a basic example to test functionality
%!test
%!  Nseg = 20;
%!  Tdata = 60*3600*Nseg;
%!  misHist = createDeltaHist(0.1);
%!  pFD = 0.1;
%!  pFA = [1e-10, 1e-8, 1e-6];
%!  Fth = 2.5;
%!  dets = "H1,L1";
%!  sigma = SensitivityDepthHoughF("Nseg", Nseg, "Tdata", Tdata, "misHist", misHist, "pFD", pFD, "pFA", pFA, "Fth", Fth, "detectors", dets);
%!  assert(max(abs(sigma - [28.070   36.547   43.370])) < 0.05);
