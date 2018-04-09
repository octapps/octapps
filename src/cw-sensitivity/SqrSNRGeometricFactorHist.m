## Copyright (C) 2016, 2017 Christoph Dreissigacker
## Copyright (C) 2011, 2016 Karl Wette
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
## @deftypefn {Function File} {@var{Rsqr} =} SqrSNRGeometricFactorHist ( @var{opt}, @var{val}, @dots{} )
##
## Calculate a histogram of the squared SNR "geometric factor", R^2
##
## @heading Arguments
##
## @table @var
## @item Rsqr
## histogram of R^2
##
## @end table
##
## @heading Options
##
## @table @code
## @item T
## observation time in sidereal days (default: inf)
##
## @item detectors
## @var{detectors} to use; either e.g. "H1,L1" or "HL" (default: L1)
##
## @item detweights
## detector weights on S_h to use (default: uniform weights)
##
## @item alpha
## source right ascension in radians (default: all-sky)
##
## @item sdelta
## sine of source declination (default: all-sky)
##
## @item psi
## source orientation in radians (default: all)
##
## @item cosi
## cosine of inclination angle (default: all)
##
## @item emission
## @var{emission} mechanism (default: nonax)
##
## @item zmstime
## sidereal time of the zero meridian at observation mid-point
##
## @item hist_dx
## histogram bin size
##
## @item hist_N
## number of histogram points to calculate at a time
##
## @item hist_err
## histogram error target
##
## @end table
##
## @end deftypefn

function Rsqr = SqrSNRGeometricFactorHist(varargin)

  ## parse options
  parseOptions(varargin,
               {"T", "real,scalar", inf},
               {"detectors", "char", "L1"},
               {"detweights", "real,strictpos,vector", []},
               {"alpha", "real,vector", [0, 2*pi]},
               {"sdelta", "real,vector", [-1, 1]},
               {"psi", "real,vector", [0, 2*pi]},
               {"cosi", "real,vector", [-1, 1]},
               {"emission", "char", "nonax"},
               {"zmstime", "real,scalar", 0},
               {"hist_dx", "real,scalar", 5e-3},
               {"hist_N", "real,scalar", 20000},
               {"hist_err", "real,scalar", 1e-4}
              );
  assert(all(isalnum(detectors) | detectors == ","), ...
         "%s: invalid detectors '%s'", funcName, detectors);

  ## product of angular sidereal frequency and observation time
  OmegaT = 2*pi*T;   ## T is in sidereal days

  ## create random parameter generator for source location parameters
  rng = CreateRandParam(alpha, sdelta, psi, cosi);
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

  ## get signal amplitude normalisation
  apxnorm = SignalAmplitudes(emission);

  ## calculate histogram of squared SNR geometric factor
  Rsqr = Hist(1, {"lin", "dbin", hist_dx});

  do

    ## new random source location parameters
    [alpha, sdelta, psi, cosi] = NextRandParam(rng, N);

    ## calculate signal amplitudes
    [ap, ax] = SignalAmplitudes(emission, cosi);

    ## calculate polarisation null vectors for this source
    [xp, yp, xx, yx] = PolarisationNullVectors(alpha, sdelta, psi);

    for n = 1:length(detectors)

      ## calculate time-averaged squared antenna patterns
      Fpsqr_t = TimeAvgSqrAntennaPattern(det(n).a0, det(n).b0, xp, yp, det(n).zeta, OmegaT);
      Fxsqr_t = TimeAvgSqrAntennaPattern(det(n).a0, det(n).b0, xx, yx, det(n).zeta, OmegaT);

      ## calculate Rsqr
      ## the normalization constant apxnorm is determined from the all-sky case,
      ## i.e. the mean over all parameters of R^2 should be 1.
      ## In the directed search case R^2 in general only depends on psi and xi therefore
      ## meanOfHist(Rsqr) should not give 1 because it is not averaging over sky
      R2 = (ap.^2 .* (detweights(n) .*Fpsqr_t) + ax.^2 .*(detweights(n).* Fxsqr_t));

      ## add new values to histogram
      Rsqr_old = Rsqr;
      Rsqr = addDataToHist(Rsqr, R2(:));

    endfor

    ## calculate difference between old and new histograms
    err = histDistance(Rsqr, Rsqr_old);

    ## continue until error is small enough
    ## (exit after 1 iteration if all parameters are constant)
  until (rng.allconst || err < hist_err)

  ## normalise R^2 histogram
  ## - the normalisation constant apxnorm is determined from the all-sky case,
  ##   i.e. the mean over all parameters of R^2 should be 1; in the directed
  ##   search case R^2 in general only depends on psi and cosi, therefore
  ##   meanOfHist(Rsqr) should not give 1 because it is not averaging over sky
  Rsqr = rescaleHistBins(Rsqr, 1.0 / apxnorm);

endfunction

%!assert(class(SqrSNRGeometricFactorHist()), "Hist")
