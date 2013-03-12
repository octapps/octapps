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

function results = Test3SkyMetric(varargin)

  ## parse options
  parseOptions(varargin,
               {"spindowns", "integer,positive,scalar"},
               {"start_time", "real,strictpos,scalar", []},
               {"ref_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephem_year", "char", []},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"sky_projection", "char"},
               {"max_mismatch", "real,strictpos,scalar", 0.5},
               {"num_trials", "integer,strictpos,scalar"},
               []);

  ## load LAL libraries
  lal;
  lalpulsar;

  ## bin widths for mismatch histograms
  relax_H_dx = 0.01;

  ## create linear phase model metrics
  [metricLPI, coordIDsLPI] = CreatePhaseMetric("coords", "ssky_equ,freq,fdots",
                                               "spindowns", spindowns,
                                               "start_time", start_time,
                                               "ref_time", ref_time,
                                               "time_span", time_span,
                                               "detectors", detectors,
                                               "fiducial_freq", fiducial_freq,
                                               "phase_model", "linearI");
  [metricLPII, coordIDsLPII] = CreatePhaseMetric("coords", "ssky_equ,freq,fdots",
                                                 "spindowns", spindowns,
                                                 "start_time", start_time,
                                                 "ref_time", ref_time,
                                                 "time_span", time_span,
                                                 "detectors", detectors,
                                                 "fiducial_freq", fiducial_freq,
                                                 "phase_model", "linearII");

  ## create 2+3-sky metric
  [metric2p3, coordIDs2p3] = CreatePhaseMetric("coords", "spin_equ,orbit_ecl,freq,fdots",
                                               "spindowns", spindowns,
                                               "start_time", start_time,
                                               "ref_time", ref_time,
                                               "time_span", time_span,
                                               "detectors", detectors,
                                               "fiducial_freq", fiducial_freq,
                                               "phase_model", "full");

  ## construct untransformed 3-sky metric
  metric3 = Construct3SkyMetrics(metric2p3, coordIDs2p3, "sky_coords", "equatorial");

  ## construct aligned 3-sky metric
  [a_metric3, a_skyoff, a_alignsky, a_coordIDs3] = Construct3SkyMetrics(metric2p3, coordIDs2p3,
                                                                        "sky_coords", "equatorial",
                                                                        "aligned_sky", true);
  ina = find(a_coordIDs3 == DOPPLERCOORD_N3X_EQU);
  inb = find(a_coordIDs3 == DOPPLERCOORD_N3Y_EQU);
  inc = find(a_coordIDs3 == DOPPLERCOORD_N3Z_EQU);
  iff = [find(a_coordIDs3 == DOPPLERCOORD_FREQ), ...
         find(a_coordIDs3 == DOPPLERCOORD_F1DOT), ...
         find(a_coordIDs3 == DOPPLERCOORD_F2DOT), ...
         find(a_coordIDs3 == DOPPLERCOORD_F3DOT)];

  ## remove aligned-c direction to create sky-projected aligned 3-sky metric
  spa_metric3 = a_metric3;
  spa_metric3(inc, :) = spa_metric3(:, inc) = [];
  assert(ina < inc);
  assert(inb < inc);
  spa_iff = iff;
  spa_iff(spa_iff > inc) -= 1;

  ## diagonally normalise sky-projected aligned metric
  [D_spa_metric3, Dnorm, iDnorm] = DiagonalNormaliseMetric(spa_metric3);

  ## compute Cholesky decomposition of diagonally-normalised sky-projected aligned metric
  CD_spa_metric3 = chol(D_spa_metric3);

  ## compute transform from surface of unit sphere to surface of sky-projected aligned
  ## metric ellipsoid with maximum mismatch of 'max_mismatch'
  onto_spa_metric3 = sqrt(max_mismatch) * Dnorm * inv(CD_spa_metric3);

  ## initalise result histograms
  results.mu_spa_metric3_relax_H = newHist(1);
  results.mu_a_metric3_relax_H = newHist(1);
  results.mu_metricLPI_relax_H = newHist(1);
  results.mu_metricLPII_relax_H = newHist(1);

  ## iterate over all trials in 'trial_block'-sized blocks
  trial_block = 1e5;
  while num_trials > 0
    if trial_block > num_trials
      trial_block = num_trials;
    endif

    ## create random point offsets on unit sphere surface
    spa_dp = randn(size(spa_metric3, 1), trial_block);
    N_spa_dp = norm(spa_dp, "cols");
    for i = 1:size(spa_dp, 1)
      spa_dp(i, :) ./= N_spa_dp;
    endfor

    ## transform point offsets to surface of sky-projected aligned
    ## metric ellipsoid with maximum mismatch of 'max_mismatch'
    spa_dp = onto_spa_metric3 * spa_dp;

    ## compute mismatch in sky-projected aligned metric
    mu_spa_metric3 = dot(spa_dp, spa_metric3 * spa_dp);

    ## create random sky points, depending on projection
    switch sky_projection
      case "orthographic"

        ## create random point in unit disk
        r = rand(1, trial_block);
        th = rand(1, trial_block) * 2*pi;
        x1 = [r .* cos(th); r .* sin(th)];

        ## add random offsets to create second random point
        x2 = x1 + spa_dp([ina, inb], :);

        ## project onto sky upper hemisphere; use real() for computing
        ## aligned-c component in case point has radius > 1
        n1 = [x1; real(sqrt(1 - sumsq(x1, 1)))];
        n2 = [x2; real(sqrt(1 - sumsq(x2, 1)))];

      otherwise
        error("%s: unknown sky projection '%s'", funcName, sky_projection);
    endswitch

    ## create point offsets in (non-sky-projected) aligned metric
    a_dp = zeros(size(a_metric3, 1), trial_block);
    a_dp([ina, inb, inc], :) = n2 - n1;
    a_dp(iff, :) = spa_dp(spa_iff, :);

    ## compute mismatch in aligned metric
    mu_a_metric3 = dot(a_dp, a_metric3 * a_dp);

    ## compute inverse coordinate transform from aligned (residual) coordinates to untransformed 3-sky coordinates
    dp = zeros(size(a_dp));
    dp([ina, inb, inc], :) = a_alignsky \ a_dp([ina, inb, inc], :);
    dp(iff, :) = a_dp(iff, :) - a_skyoff * a_dp([ina, inb, inc], :);

    ## compute mismatch in untransformed metric
    mu_metric3 = dot(dp, metric3 * dp);

    ## bin relaxation of sky-projected aligned mismatch compared to untransformed mismatch
    mu_spa_metric3_relax = mu_spa_metric3 ./ mu_metric3;
    results.mu_spa_metric3_relax_H = addDataToHist(results.mu_spa_metric3_relax_H, mu_spa_metric3_relax(:), relax_H_dx);

    ## bin relaxation of aligned mismatch compared to untransformed mismatch
    mu_a_metric3_relax = mu_a_metric3 ./ mu_metric3;
    results.mu_a_metric3_relax_H = addDataToHist(results.mu_a_metric3_relax_H, mu_a_metric3_relax(:), relax_H_dx);

    ## compute mismatch in metric with linear phase model I
    mu_metricLPI = dot(dp, metricLPI * dp);

    ## bin relaxation of linear phase model I metric compared to untransformed mismatch
    mu_metricLPI_relax = mu_metricLPI ./ mu_metric3;
    results.mu_metricLPI_relax_H = addDataToHist(results.mu_metricLPI_relax_H, mu_metricLPI_relax(:), relax_H_dx);

    ## compute mismatch in metric with linear phase model II
    mu_metricLPII = dot(dp, metricLPII * dp);

    ## bin relaxation of linear phase model II metric compared to untransformed mismatch
    mu_metricLPII_relax = mu_metricLPII ./ mu_metric3;
    results.mu_metricLPII_relax_H = addDataToHist(results.mu_metricLPII_relax_H, mu_metricLPII_relax(:), relax_H_dx);

    num_trials -= trial_block;
  endwhile

endfunction
