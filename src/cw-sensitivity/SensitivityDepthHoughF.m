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

## -*- texinfo -*-
## @deftypefn  {Function File} @var{sensDepth} = SensitivityDepthHoughF(@var{opt}, @var{val}, @dots{})
##
## Estimate Hough-on-Fstat sensitivity depth, defined as
##
## @var{sensDepth} = sqrt(@var{Sdata})/@var{h0},
##
## where
##
## @table @var
## @item Sdata
## an estimate of the noise PSD over all the data used (which should be computed
## as the harmonic mean over all the SFTs from all @var{detectors})
## @item h0
## the smallest detectable GW amplitude at the given false-alarm (@var{pFA}) and
## false-dismissal probability (@var{pFD})
## @end table
##
## @heading Options
##
## @table @code
## @item Nseg
## number of Hough segments
##
## @item Tdata
## total amount of data used, in seconds
## (Note: @var{Tdata} = @var{Nsft} * @var{Tsft}, where @var{Nsft} is the total number of
## SFTs of length @var{Tsft} used in the search, from all @var{detectors})
##
## @item misHist
## mismatch histogram, produced using @command{Hist()}
##
## @item pFD
## false-dismissal probability = 1 - pDet
##
## @item pFA
## false-alarm probability (-ies) *per template* (can be a vector)
##
## @item Fth
## F-stat threshold (on F, not 2F!) in each segment for "pixel" selection
##
## @item detectors
## CSV list of @var{detectors} to use ("H1"=Hanford, "L1"=Livingston, "V1"=Virgo, @var{...})
##
## @item detweights
## detector weights on S_h to use (default: uniform weights)
##
## @item alpha
## source right ascension in radians (default: all-sky)
##
## @item delta
## source declination (default: all-sky)
##
## @end table
##
## @end deftypefn

function sensDepth = SensitivityDepthHoughF ( varargin )

  ## parse options
  uvar = parseOptions ( varargin,
                        {"Nseg", "integer,strictpos,column", 1 },
                        {"Tdata", "real,strictpos,column" },
                        {"misHist", "acell:Hist" },
                        {"pFD", "real,strictpos,column", 0.1},
                        {"pFA", "real,strictpos,vector"},
                        {"Fth", "real,strictpos,column", 5.2/2 },
                        {"detectors", "char", "H1,L1" },
                        {"detweights", "real,strictpos,vector", []},
                        {"alpha", "real,vector", [0, 2*pi]},
                        {"delta", "real,vector", [-pi/2, pi/2]},
                        []);

  ## compute sensitivity SNR
  Rsqr = SqrSNRGeometricFactorHist("detectors", uvar.detectors, "detweights", uvar.detweights, "alpha", uvar.alpha, "sdelta", sin(uvar.delta) );
  [sensDepth, pd_Depth] = SensitivityDepth ( "pd", uvar.pFD, "Ns", uvar.Nseg,"Tdata", uvar.Tdata, "Rsqr", Rsqr,"misHist", uvar.misHist, "stat", {"HoughFstat", "paNt", uvar.pFA, "Fth", uvar.Fth});

endfunction

## a basic example to test functionality
%!test
%!  Nseg = 20;
%!  Tdata = 60*3600*Nseg;
%!  misHist = createDeltaHist(0.1);
%!  pFD = 0.1;
%!  pFA = [1e-10; 1e-8; 1e-6];
%!  Fth = 2.5;
%!  dets = "H1,L1";
%!  sigma = SensitivityDepthHoughF("Nseg", Nseg, "Tdata", Tdata, "misHist", misHist, "pFD", pFD, "pFA", pFA, "Fth", Fth, "detectors", dets);
%!  assert(max(abs(sigma - [27.442; 35.784; 42.490])) < 0.05);
