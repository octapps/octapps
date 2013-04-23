## Copyright (C) 2013 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Test the super-sky metric with random offsets.
## Usage:
##   results = TestSuperSkyMetric(...)
## where:
##   results = struct containing:
##     ssmetric_lpI  = super-sky metric computed with JKS's linear I phase model
##     ssmetric_lpII = super-sky metric computed with JKS's linear II phase model
##     ssmetric      = super-sky metric
##     a_ssmetric    = aligned super-sky metric
##     mu_spa_ssmetric_err_H  = error in sky-projected aligned mismatch compared to untransformed mismatch
##     mu_a_ssmetric_err_H    = error in aligned mismatch compared to untransformed mismatch
##     mu_ssmetric_lpI_err_H  = error in linear phase model I metric compared to untransformed mismatch
##     mu_ssmetric_lpII_err_H = error in linear phase model II metric compared to untransformed mismatch
##     mu_ssmetric_ad_err_H   = error in mismatch using physical coordinates compared to untransformed mismatch
## Options:
##   spindowns: number of frequency spindowns coordinates
##   start_time: start time in GPS seconds (default: see CreatePhaseMetric)
##   ref_time: reference time in GPS seconds (default: see CreatePhaseMetric)
##   time_span: observation time-span in seconds
##   detectors: comma-separated list of detector names
##   ephem_year: ephemerides year (default: see CreatePhaseMetric)
##   fiducial_freq: fiducial frequency for sky-position coordinates
##   sky_coords: sky coordinate system to use (default: equatorial)
##   aligned_sky: whether to align sky coordinates (default: true)
##   max_mismatch: maximum prescribed mismatch to test at
##   num_trials: number of trials to perform
##   err_H_minrange: minimum range of error histogram bins (default: 0.01)
##   err_H_binsper10: number of error histogram bins per decade (default: 10)

function results = TestSuperSkyMetric(varargin)

  ## parse options
  parseOptions(varargin,
               {"spindowns", "integer,positive,scalar"},
               {"start_time", "real,strictpos,scalar", []},
               {"ref_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephem_year", "char", []},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"sky_coords", "char", "equatorial"},
               {"aligned_sky", "logical,scalar", true},
               {"max_mismatch", "real,strictpos,scalar", 0.5},
               {"num_trials", "integer,strictpos,scalar"},
               {"err_H_minrange", "real,strictpos,scalar", 0.01},
               {"err_H_binsper10", "integer,strictpos,scalar", 10},
               []);

  ## load LAL libraries
  lal;
  lalpulsar;

  ## create spin-orbit component metric
  [sometric, socoordIDs] = CreatePhaseMetric("coords", "spin_equ,orbit_ecl,freq,fdots",
                                             "spindowns", spindowns,
                                             "start_time", start_time,
                                             "ref_time", ref_time,
                                             "time_span", time_span,
                                             "detectors", detectors,
                                             "fiducial_freq", fiducial_freq,
                                             "det_motion", "spin+orbit");

  ## construct untransformed super-sky metric
  results.ssmetric = ConstructSuperSkyMetrics(sometric, socoordIDs, "sky_coords", sky_coords);

  ## construct aligned super-sky metric
  [results.a_ssmetric, a_skyoff, a_alignsky, a_sscoordIDs] = ConstructSuperSkyMetrics(sometric, socoordIDs,
                                                                                      "sky_coords", sky_coords,
                                                                                      "aligned_sky", aligned_sky);
  switch sky_coords
    case "equatorial"
      ina = find(a_sscoordIDs == DOPPLERCOORD_N3X_EQU);
      inb = find(a_sscoordIDs == DOPPLERCOORD_N3Y_EQU);
      inc = find(a_sscoordIDs == DOPPLERCOORD_N3Z_EQU);
    case "ecliptic"
      ina = find(a_sscoordIDs == DOPPLERCOORD_N3X_ECL);
      inb = find(a_sscoordIDs == DOPPLERCOORD_N3Y_ECL);
      inc = find(a_sscoordIDs == DOPPLERCOORD_N3Z_ECL);
    otherwise
      error("%s: unknown coordinate system '%s'", funcName, sky_coords);
  endswitch
  iff = [find(a_sscoordIDs == DOPPLERCOORD_FREQ), ...
         find(a_sscoordIDs == DOPPLERCOORD_F1DOT), ...
         find(a_sscoordIDs == DOPPLERCOORD_F2DOT), ...
         find(a_sscoordIDs == DOPPLERCOORD_F3DOT)];

  ## remove aligned-c direction to create sky-projected aligned super-sky metric
  spa_ssmetric = results.a_ssmetric;
  spa_ssmetric(inc, :) = spa_ssmetric(:, inc) = [];
  assert(ina < inc);
  assert(inb < inc);
  spa_iff = iff;
  spa_iff(spa_iff > inc) -= 1;

  ## diagonally normalise sky-projected aligned metric
  [D_spa_ssmetric, Dnorm, iDnorm] = DiagonalNormaliseMetric(spa_ssmetric);

  ## compute Cholesky decomposition of diagonally-normalised sky-projected aligned metric
  CD_spa_ssmetric = chol(D_spa_ssmetric);

  ## compute transform from surface of unit sphere to surface of sky-projected aligned
  ## metric ellipsoid with maximum mismatch of 'max_mismatch'
  onto_spa_ssmetric = sqrt(max_mismatch) * Dnorm * inv(CD_spa_ssmetric);

  ## create linear phase model metrics from Andrzej Krolak etal's papers
  [results.ssmetric_lpI, sscoordIDs_lpI] = CreatePhaseMetric("coords", "ssky_equ,freq,fdots",
                                                             "spindowns", spindowns,
                                                             "start_time", start_time,
                                                             "ref_time", ref_time,
                                                             "time_span", time_span,
                                                             "detectors", detectors,
                                                             "fiducial_freq", fiducial_freq,
                                                             "det_motion", "spinxy+orbit");
  [results.ssmetric_lpII, sscoordIDs_lpII] = CreatePhaseMetric("coords", "ssky_equ,freq,fdots",
                                                               "spindowns", spindowns,
                                                               "start_time", start_time,
                                                               "ref_time", ref_time,
                                                               "time_span", time_span,
                                                               "detectors", detectors,
                                                               "fiducial_freq", fiducial_freq,
                                                               "det_motion", "orbit");

  ## initalise result histograms
  results.mu_spa_ssmetric_err_H = Hist(1, {"log", "minrange", err_H_minrange, "binsper10", err_H_binsper10});
  results.mu_a_ssmetric_err_H = Hist(1, {"log", "minrange", err_H_minrange, "binsper10", err_H_binsper10});
  results.mu_ssmetric_lpI_err_H = Hist(1, {"log", "minrange", err_H_minrange, "binsper10", err_H_binsper10});
  results.mu_ssmetric_lpII_err_H = Hist(1, {"log", "minrange", err_H_minrange, "binsper10", err_H_binsper10});
  results.mu_ssmetric_ad_err_H = Hist(1, {"log", "minrange", err_H_minrange, "binsper10", err_H_binsper10});

  ## iterate over all trials in 'trial_block'-sized blocks
  trial_block = 1e5;
  while num_trials > 0
    if trial_block > num_trials
      trial_block = num_trials;
    endif

    ## create random point offsets on unit sphere surface
    spa_dp = randn(size(spa_ssmetric, 1), trial_block);
    N_spa_dp = norm(spa_dp, "cols");
    for i = 1:size(spa_dp, 1)
      spa_dp(i, :) ./= N_spa_dp;
    endfor

    ## transform point offsets to surface of sky-projected aligned
    ## metric ellipsoid with maximum mismatch of 'max_mismatch'
    spa_dp = onto_spa_ssmetric * spa_dp;

    ## compute mismatch in sky-projected aligned metric
    mu_spa_ssmetric = dot(spa_dp, spa_ssmetric * spa_dp);

    ## create random point in unit disk
    r = rand(1, trial_block);
    th = rand(1, trial_block) * 2*pi;
    x1 = [r .* cos(th); r .* sin(th)];

    ## get random offset and compute dot products
    dx = spa_dp([ina, inb], :);
    x1_x1 = dot(x1, x1);
    x1_dx = dot(x1, dx);
    dx_dx = dot(dx, dx);

    ## compute the constant multiplier 'c' required to satisfy
    ## |x1 + c*dx| == 1; if it is less than 1, then |x + dx| > 1
    ## and second random point would lie outside sky sphere,
    ## thus limit 'c' to be less than 1.
    c = ( sqrt(x1_dx.^2 + dx_dx.*(1 - x1_x1)) - x1_dx ) ./ dx_dx;
    c = min(1.0, c);

    ## compute second random point by adding (scaled) offset
    x2 = x1;
    for i = 1:2
      x2(i, :) += c .* dx(i, :);
    endfor

    ## project onto (aligned sky) upper hemisphere; use real()
    ## in case points have radius >1 due to numerical roundoff
    a_n1 = [x1; real(sqrt(1 - sumsq(x1)))];
    a_n2 = [x2; real(sqrt(1 - sumsq(x2)))];

    ## create point offsets in (non-sky-projected) aligned metric
    a_dp = zeros(size(results.a_ssmetric, 1), trial_block);
    a_dp([ina, inb, inc], :) = a_n2 - a_n1;
    a_dp(iff, :) = spa_dp(spa_iff, :);

    ## compute mismatch in aligned metric
    mu_a_ssmetric = dot(a_dp, results.a_ssmetric * a_dp);

    ## compute inverse coordinate transform from aligned (residual) coordinates to untransformed super-sky coordinates
    n1 = a_alignsky \ a_n1;
    n2 = a_alignsky \ a_n2;
    dp = zeros(size(a_dp));
    dp([ina, inb, inc], :) = n2 - n1;
    dp(iff, :) = a_dp(iff, :) - a_skyoff * a_dp([ina, inb, inc], :);

    ## compute mismatch in untransformed metric
    mu_ssmetric = dot(dp, results.ssmetric * dp);

    ## bin error in sky-projected aligned mismatch compared to untransformed mismatch
    mu_spa_ssmetric_err = mu_spa_ssmetric ./ mu_ssmetric - 1;
    results.mu_spa_ssmetric_err_H = addDataToHist(results.mu_spa_ssmetric_err_H, mu_spa_ssmetric_err(:));

    ## bin error in aligned mismatch compared to untransformed mismatch
    mu_a_ssmetric_err = mu_a_ssmetric ./ mu_ssmetric - 1;
    results.mu_a_ssmetric_err_H = addDataToHist(results.mu_a_ssmetric_err_H, mu_a_ssmetric_err(:));

    ## compute mismatch in metric with linear phase model I
    mu_ssmetric_lpI = dot(dp, results.ssmetric_lpI * dp);

    ## bin error in linear phase model I metric compared to untransformed mismatch
    mu_ssmetric_lpI_err = mu_ssmetric_lpI ./ mu_ssmetric - 1;
    results.mu_ssmetric_lpI_err_H = addDataToHist(results.mu_ssmetric_lpI_err_H, mu_ssmetric_lpI_err(:));

    ## compute mismatch in metric with linear phase model II
    mu_ssmetric_lpII = dot(dp, results.ssmetric_lpII * dp);

    ## bin error in linear phase model II metric compared to untransformed mismatch
    mu_ssmetric_lpII_err = mu_ssmetric_lpII ./ mu_ssmetric - 1;
    results.mu_ssmetric_lpII_err_H = addDataToHist(results.mu_ssmetric_lpII_err_H, mu_ssmetric_lpII_err(:));

    ## compute right ascensions alpha1 and alpha2 from sky positions n1 and n2
    alpha1 = atan2(n1(2, :), n1(1, :));
    alpha2 = atan2(n2(2, :), n2(1, :));

    ## compute declinations delta1 and delta2 from sky positions n1 and n2
    delta1 = atan2(n1(3, :), sqrt(sumsq(n1(1:2, :))));
    delta2 = atan2(n2(3, :), sqrt(sumsq(n2(1:2, :))));

    ## compute "equivalent" sky position offset in physical coordinates (alpha,delta),
    ## evaluated at (alpha1,delta1). ad_dp is a product of the Jacobian matrix
    ##   \partial(\cos\alpha\cos\delta, \sin\alpha\cos\delta, \sin\delta)/\partial(\alpha,\delta)
    ## and the physical offsets
    ##   (\Delta\alpha, \Delta\delta)
    cosalpha = cos(alpha1);
    sinalpha = sin(alpha1);
    cosdelta = cos(delta1);
    sindelta = sin(delta1);
    dalpha = alpha2 - alpha1;
    ddelta = delta2 - delta1;
    ad_dp = dp;
    ad_dp(ina, :) = -sinalpha.*cosdelta.*dalpha - cosalpha.*sindelta.*ddelta;
    ad_dp(inb, :) = cosalpha.*cosdelta.*dalpha - sinalpha.*sindelta.*ddelta;
    ad_dp(inc, :) = cosdelta.*ddelta;

    ## compute mismatch in metric using physical coordinates (alpha,delta)
    mu_ssmetric_ad = dot(ad_dp, results.ssmetric * ad_dp);

    ## bin error in metric using physical coordinates compared to untransformed mismatch
    mu_ssmetric_ad_err = mu_ssmetric_ad ./ mu_ssmetric - 1;
    results.mu_ssmetric_ad_err_H = addDataToHist(results.mu_ssmetric_ad_err_H, mu_ssmetric_ad_err(:));

    num_trials -= trial_block;
  endwhile

endfunction
