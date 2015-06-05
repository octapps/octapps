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

## Estimate StackSlide sensitivity depth sensDepth = sqrt(Sh)/h0
## Usage:
##   sensDepth = SensitivityDepthStackSlide("opt", val, ...)
## Options are:
##   "Nseg":            number of StackSlide segments
##   "Tdata":           total amount of data used, in seconds
##   "misHist":         mismatch histogram, produced using Hist()
##   "pFD":             false-dismissal probability = 1 - pDet
##   "pFA":             false-alarm probability (-ies) *per template* (can be a vector)
##   "detectors":       string containing detector-network to use ("H"=Hanford, "L"=Livingston, "V"=Virgo)
##   "alpha":           source right ascension in radians (default: all-sky)
##   "delta":           source declination (default: all-sky)

function sensDepth = SensitivityDepthStackSlide ( varargin )

  ## parse options
  uvar = parseOptions ( varargin,
                       {"Nseg", "integer,strictpos,scalar", 1 },
                       {"Tdata", "real,strictpos,scalar" },
                       {"misHist", "Hist" },
                       {"pFD", "real,strictpos,scalar", 0.1},
                       {"pFA", "real,strictpos,vector"},
                       {"detectors", "char", "HL" },
                       {"alpha", "real,vector", [0, 2*pi]},
                       {"delta", "real,vector", [-1, 1]},
                       []);

  ## compute sensitivity SNR
  Rsqr = SqrSNRGeometricFactorHist("detectors", uvar.detectors, "mism_hgrm", uvar.misHist, "alpha", uvar.alpha, "sdelta", sin(uvar.delta) );
  rho = SensitivitySNR ( uvar.pFD, uvar.Nseg, Rsqr, "ChiSqr", "paNt", uvar.pFA );

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
%!  pFA = [1e-14, 1e-12, 1e-10];
%!  dets = "HL";
%!  sigma = SensitivityDepthStackSlide("Nseg", Nseg, "Tdata", Tdata, "misHist", misHist, "pFD", pFD, "pFA", pFA, "detectors", dets);
%!  assert(max(abs(sigma - [38.038, 40.114, 42.682])) < 0.05);
