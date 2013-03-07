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
               {"ptolemaic", "logical,scalar", []},
               {"max_mismatch", "real,strictpos,scalar", 0.5},
               {"num_trials", "integer,strictpos,scalar", 1e6},
               []);

  ## load LAL libraries
  lal;
  lalpulsar;

  ## bin widths for mismatch histograms
  lgerr_H_dx = 0.1;

  ## create 2+3-sky metric
  [metric2p3, coordIDs2p3] = CreatePhaseMetric("coords", "spin_equ,orbit_ecl,freq,fdots",
                                               "spindowns", spindowns,
                                               "start_time", start_time,
                                               "ref_time", ref_time,
                                               "time_span", time_span,
                                               "detectors", detectors,
                                               "fiducial_freq", fiducial_freq,
                                               "ptolemaic", ptolemaic);

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

  ## remove aligned-c direction to create reduced-aligned 3-sky metric
  ra_metric3 = a_metric3;
  ra_metric3(inc, :) = ra_metric3(:, inc) = [];

  ## diagonally normalise reduced-aligned metric
  [D_ra_metric3, Dnorm, iDnorm] = DiagonalNormaliseMetric(ra_metric3);

  ## compute Cholesky decomposition of diagonally-normalised reduced-aligned metric
  CD_ra_metric3 = chol(D_ra_metric3);

  ## compute transform from surface of unit sphere to surface of reduced-aligned
  ## metric ellipsoid with maximum mismatch of 'max_mismatch'
  onto_ra_metric3 = sqrt(max_mismatch) * Dnorm * inv(CD_ra_metric3);

  ## initalise result histograms
  results.mu_ra_metric3_lgerr_H = newHist(1);
  results.mu_a_metric3_lgerr_H = newHist(2);
  results.mu_metric3_lgerr_H = newHist(1);

  ## iterate over all trials in 'trial_block'-sized blocks
  trial_block = 1e5;
  while num_trials > 0
    if trial_block > num_trials
      trial_block = num_trials;
    endif

    ## create random point offsets on unit sphere surface
    ra_dp = randn(size(ra_metric3, 1), trial_block);
    N_ra_dp = norm(ra_dp, "cols");
    for i = 1:size(ra_metric3, 1)
      ra_dp(i, :) ./= N_ra_dp;
    endfor

    ## transform point offsets to surface of reduced-aligned
    ## metric ellipsoid with maximum mismatch of 'max_mismatch'
    ra_dp = onto_ra_metric3 * ra_dp;

    ## compute mismatch in reduced-aligned metric
    mu_ra_metric3 = dot(ra_dp, ra_metric3 * ra_dp);

    ## bin error in reduced-aligned mismatch compared to 'max_mismatch'
    mu_ra_metric3_lgerr = log10(abs(mu_ra_metric3 - max_mismatch) ./ max_mismatch);
    results.mu_ra_metric3_lgerr_H = addDataToHist(results.mu_ra_metric3_lgerr_H, mu_ra_metric3_lgerr(:), lgerr_H_dx);

    ## create random radius and angle in aligned-a-b space (unit circle)
    nr = rand(1, trial_block);
    nth = rand(1, trial_block) * 2*pi;

    ## create random point in aligned sky sphere
    nab1 = [nr .* cos(nth); nr .* sin(nth)];
    ## use real when computing nc1 in case point has radius > 1
    nc1 = real(sqrt(1 - sumsq(nab1, 1)));

    ## create second random point by adding random offsets
    nab2 = nab1 + ra_dp([ina, inb], :);
    ## use real when computing nc2 in case point has radius > 1
    nc2 = real(sqrt(1 - sumsq(nab2, 1)));

    ## create point offsets in (non-reduced) aligned metric
    a_dp = zeros(size(a_metric3, 1), trial_block);
    a_dp([1:inc-1 inc+1:end], :) = ra_dp;
    a_dp(inc, :) = nc2 - nc1;

    ## compute mismatch in aligned metric
    mu_a_metric3 = dot(a_dp, a_metric3 * a_dp);

    ## bin error in aligned mismatch compared to reduced-aligned mismatch, as function of aligned-a-b radius
    mu_a_metric3_lgerr = log10(abs(mu_a_metric3 - mu_ra_metric3) ./ mu_ra_metric3);
    results.mu_a_metric3_lgerr_H = addDataToHist(results.mu_a_metric3_lgerr_H, [mu_a_metric3_lgerr(:), nr(:)], lgerr_H_dx);

    ## compute inverse coordinate transform from aligned (residual) coordinates to untransformed 3-sky coordinates
    dp = zeros(size(a_dp));
    dp([ina, inb, inc], :) = a_alignsky \ a_dp([ina, inb, inc], :);
    dp(iff, :) = a_dp(iff, :) - a_skyoff * a_dp([ina, inb, inc], :);

    ## compute mismatch in untransformed metric
    mu_metric3 = dot(dp, metric3 * dp);

    ## bin error in untransformed mismatch compared to aligned mismatch
    mu_metric3_lgerr = log10(abs(mu_metric3 - mu_a_metric3) ./ mu_a_metric3);
    results.mu_metric3_lgerr_H = addDataToHist(results.mu_metric3_lgerr_H, mu_metric3_lgerr(:), lgerr_H_dx);

    num_trials -= trial_block;
  endwhile

endfunction
