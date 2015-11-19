## Copyright (C) 2011 Karl Wette
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

## Calculate a histogram of the squared SNR "geometric factor", R^2
## Syntax:
##   Rsqr_H      = SqrSNRGeometricFactorHist("opt", val, ...)
## where:
##   Rsqr_H      = histogram of R^2
## and where options are:
##   "T"         = observation time in sidereal days (default: inf)
##   "detectors" = detectors to use; either e.g. "H1,L1" or "HL" (default: L1)
##   "detweights"= detector weights on S_h to use (default: uniform weights)
##   "mism_hgrm" = mismatch histogram (default: no mismatch)
##   "alpha"     = source right ascension in radians (default: all-sky)
##   "sdelta"    = sine of source declination (default: all-sky)
##   "psi"       = source orientation in radians (default: all)
##   "cosi"      = cosine of inclination angle (default: all)
##   "emission"  = emission mechanism (default: nonax)
##   "zmstime"   = sidereal time of the zero meridian at observation mid-point
##   "hist_dx"   = histogram bin size
##   "hist_N"    = number of histogram points to calculate at a time
##   "hist_err"  = histogram error target

function Rsqr_H = SqrSNRGeometricFactorHist(varargin)

  ## parse options
  parseOptions(varargin,
               {"T", "numeric,scalar", inf},
               {"detectors", "char", "L1"},
               {"detweights", "real,strictpos,vector", []},
               {"mism_hgrm", "Hist", []},
               {"alpha", "numeric,vector", [0, 2*pi]},
               {"sdelta", "numeric,vector", [-1, 1]},
               {"psi", "numeric,vector", [0, 2*pi]},
               {"cosi", "numeric,vector", [-1, 1]},
               {"emission", "char", "nonax"},
               {"zmstime", "numeric,scalar", 0},
               {"hist_dx", "numeric,scalar", 5e-3},
               {"hist_N", "numeric,scalar", 20000},
               {"hist_err", "numeric,scalar", 1e-4}
               );
  assert(all(isalnum(detectors) | detectors == ","), ...
         "%s: invalid detectors '%s'", funcName, detectors);

  ## restrict mismatch histogram to range [0.0, 1.0]
  if ~isempty(mism_hgrm)
    mism_hgrm = restrictHist(mism_hgrm, [0.0, 1.0]);
  endif

  ## product of angular sidereal frequency and observation time
  OmegaT = 2*pi*T;   # T is in sidereal days

  ## create random parameter generator for source location parameters
  rng = CreateRandParam(alpha, sdelta, psi);
  N = !!rng.allconst + !rng.allconst*hist_N;

  ## remove non-letters from 'detectors', so that e.g. "H1,L1" becomes "HL"
  detectors = detectors(isalpha(detectors));

  ## check detector weights; use uniform weights if not specified,
  ## then normalise weights by their mean
  assert(isempty(detweights) || length(detweights) == length(detectors));
  if isempty(detweights)
     detweights = ones(1, length(detectors));
  endif
  detweights /= mean(detweights);

  ## calculate detector null vectors at t=0 for each detector
  det = struct;
  for n = 1:length(detectors)

    ## detector null vectors for nth detector
    [L, slambda, gamma, det(n).zeta] = DetectorLocations(detectors(n));

    ## calculate local sidereal time at detector
    Phis = L + zmstime;

    ## detector null vectors at t=0
    [a0, b0] = DetectorNullVectors(Phis, slambda, gamma);
    det(n).a0 = a0(:,ones(1,N));
    det(n).b0 = b0(:,ones(1,N));
    clear a0 b0;

  endfor

  ## calculate squared antenna patterns averaged over time and source location parameters
  Fpsqr_t_H = Fxsqr_t_H = Hist(1, {"lin", "dbin", hist_dx});
  do

    ## new random source location parameters
    [alpha, sdelta, psi] = NextRandParam(rng, N);

    ## calculate polarisation null vectors for this source
    [xp, yp, xx, yx] = PolarisationNullVectors(alpha, sdelta, psi);

    ## loop over detectors
    Fpsqr_t_H_old = Fpsqr_t_H;
    Fxsqr_t_H_old = Fxsqr_t_H;
    for n = 1:length(detectors)

      ## calculate time-averaged squared antenna patterns
      Fpsqr_t = TimeAvgSqrAntennaPattern(det(n).a0, det(n).b0, xp, yp, det(n).zeta, OmegaT);
      Fxsqr_t = TimeAvgSqrAntennaPattern(det(n).a0, det(n).b0, xx, yx, det(n).zeta, OmegaT);

      ## add new values to histograms, weighted by detector weights
      Fpsqr_t_H = addDataToHist(Fpsqr_t_H, detweights(n) * Fpsqr_t(:));
      Fxsqr_t_H = addDataToHist(Fxsqr_t_H, detweights(n) * Fxsqr_t(:));

    endfor

    ## calculate difference between old and new histograms
    err = max(histDistance(Fpsqr_t_H, Fpsqr_t_H_old),
              histDistance(Fxsqr_t_H, Fxsqr_t_H_old));

    ## continue until error is small enough
    ## (exit after 1 iteration if all parameters are constant)
  until (rng.allconst || err < hist_err)

  ## average of squared antenna patterns over time and source location parameters
  avg_Fpsqr_t = meanOfHist(Fpsqr_t_H);
  avg_Fxsqr_t = meanOfHist(Fxsqr_t_H);

  ## get signal amplitude normalisation
  apxnorm = SignalAmplitudes(emission);

  ## create random parameter generator for source amplitude parameters
  rng = CreateRandParam(cosi);
  N = !!rng.allconst + !rng.allconst*hist_N;

  ## calculate histogram of squared SNR geometric factor
  Rsqr_H = Hist(1, {"lin", "dbin", hist_dx});
  do

    ## new random source amplitude parameters
    [cosi] = NextRandParam(rng, N);

    ## calculate signal amplitudes
    [ap, ax] = SignalAmplitudes(emission, cosi);

    ## calculate squared SNR geometric factor
    Rsqr = (ap.^2 .* avg_Fpsqr_t) + (ax.^2 .* avg_Fxsqr_t);

    ## if using mismatch histogram, reduce R^2 by randomly-chosen mismatch
    if ~isempty(mism_hgrm)
      mismatch = drawFromHist(mism_hgrm, N);
      Rsqr .*= ( 1 - mismatch' );
    endif

    ## add new values to histogram
    Rsqr_H_old = Rsqr_H;
    Rsqr_H = addDataToHist(Rsqr_H, Rsqr(:));

    ## calculate difference between old and new histograms
    err = histDistance(Rsqr_H, Rsqr_H_old);

    ## continue until error is small enough
    ## (exit after 1 iteration if all parameters are constant)
  until (rng.allconst || err < hist_err)

  ## reduce scale of R^2 histogram so that <R^2> = 1
  Rsqr_H = rescaleHistBins(Rsqr_H, 1.0 / apxnorm);

endfunction
