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

## Test the super-sky metric with random offsets and (optionally) full software injections.
## Usage:
##   results = TestSuperSkyMetric(...)
## where results struct contains:
##   metrics:
##     ssmetric_lpI       = super-sky metric computed with JKS's linear I phase model
##     ssmetric_lpII      = super-sky metric computed with JKS's linear II phase model
##     ssmetric           = super-sky metric
##     a_ssmetric         = aligned super-sky metric
##     a_skyoff           = aligned super-sky metric sky offset vectors
##     a_alignsky         = aligned super-sky metric sky alignment rotation
##   mismatch error histograms parameterised by injection parameters:
##     mu_spa_ssmetric_H  = error in sky-projected aligned mismatch compared to untransformed mismatch
##     mu_a_ssmetric_H    = error in aligned mismatch compared to untransformed mismatch
##     mu_ssmetric_lpI_H  = error in linear phase model I metric compared to untransformed mismatch
##     mu_ssmetric_lpII_H = error in linear phase model II metric compared to untransformed mismatch
##     mu_ssmetric_ad_H   = error in mismatch using physical coordinates compared to untransformed mismatch
##     mu_twoF_H          = (optional) error in full software injections mismatch compared to untransformed mismatch
## Options:
##   spindowns: number of frequency spindowns coordinates
##   start_time: start time in GPS seconds (default: see CreatePhaseMetric)
##   ref_time: reference time in GPS seconds (default: see CreatePhaseMetric)
##   time_span: observation time-span in seconds
##   detectors: comma-separated list of detector names
##   ephemerides: Earth/Sun ephemerides from loadEphemerides()
##   fiducial_freq: fiducial frequency at which to perform tests
##   sky_coords: sky coordinate system to use (default: equatorial)
##   aligned_sky: whether to align sky coordinates (default: true)
##   max_mismatch: maximum prescribed mismatch to test at
##   num_injections: number of injections to perform
##   num_cpu_seconds: number of CPU seconds to perform injections for
##   full_injections: whether to perform full software injections (default: true)
##   injection_block: number of injections to perform at once (default: 100)

function results = TestSuperSkyMetric(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"spindowns", "integer,positive,scalar"},
               {"start_time", "real,strictpos,scalar", []},
               {"ref_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephemerides", "a:swig_ref", []},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"sky_coords", "char", "equatorial"},
               {"aligned_sky", "logical,scalar", true},
               {"max_mismatch", "real,strictpos,scalar", 0.5},
               {"num_injections", "integer,strictpos,scalar", inf},
               {"num_cpu_seconds", "real,strictpos,scalar", inf},
               {"full_injections", "logical,scalar", true},
               {"injection_block", "integer,strictpos,scalar", 100},
               []);
  if !xor(isfinite(num_injections), isfinite(num_cpu_seconds))
    error("%s: must give either num_injections or num_cpu_seconds", funcName);
  endif

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## create spin-orbit component metric
  [results.sometric, socoordIDs, start_time, ref_time] = ...
      CreatePhaseMetric("coords", "spin_equ,orbit_ecl,freq,fdots",
                        "spindowns", spindowns,
                        "start_time", start_time,
                        "ref_time", ref_time,
                        "time_span", time_span,
                        "detectors", detectors,
                        "ephemerides", ephemerides,
                        "fiducial_freq", fiducial_freq,
                        "det_motion", "spin+orbit");

  ## construct untransformed super-sky metric
  [results.ssmetric, _, _, sscoordIDs] = ...
      ConstructSuperSkyMetrics(results.sometric, socoordIDs,
                               "sky_coords", sky_coords);

  ## determine indices of super-sky metric coordinates
  ina = find(sscoordIDs == DOPPLERCOORD_N3X_EQU | sscoordIDs == DOPPLERCOORD_N3X_ECL);
  inb = find(sscoordIDs == DOPPLERCOORD_N3Y_EQU | sscoordIDs == DOPPLERCOORD_N3Y_ECL);
  inc = find(sscoordIDs == DOPPLERCOORD_N3Z_EQU | sscoordIDs == DOPPLERCOORD_N3Z_ECL);
  iff = [find(sscoordIDs == DOPPLERCOORD_FREQ), ...
         find(sscoordIDs == DOPPLERCOORD_F1DOT), ...
         find(sscoordIDs == DOPPLERCOORD_F2DOT), ...
         find(sscoordIDs == DOPPLERCOORD_F3DOT)];

  ## construct aligned super-sky metric
  [results.a_ssmetric, results.a_skyoff, results.a_alignsky, a_sscoordIDs] = ...
      ConstructSuperSkyMetrics(results.sometric, socoordIDs,
                               "sky_coords", sky_coords,
                               "aligned_sky", aligned_sky);
  assert(all(a_sscoordIDs == sscoordIDs));

  ## create linear phase model metrics from Andrzej Krolak etal's papers
  [results.ssmetric_lpI, sscoordIDs_lpI] = ...
      CreatePhaseMetric("coords", "ssky_equ,freq,fdots",
                        "spindowns", spindowns,
                        "start_time", start_time,
                        "ref_time", ref_time,
                        "time_span", time_span,
                        "detectors", detectors,
                        "ephemerides", ephemerides,
                        "fiducial_freq", fiducial_freq,
                        "det_motion", "spinxy+orbit");
  assert(all(sscoordIDs_lpI == sscoordIDs));
  [results.ssmetric_lpII, sscoordIDs_lpII] = ...
      CreatePhaseMetric("coords", "ssky_equ,freq,fdots",
                        "spindowns", spindowns,
                        "start_time", start_time,
                        "ref_time", ref_time,
                        "time_span", time_span,
                        "detectors", detectors,
                        "ephemerides", ephemerides,
                        "fiducial_freq", fiducial_freq,
                        "det_motion", "orbit");
  assert(all(sscoordIDs_lpII == sscoordIDs));

  ## remove aligned-c direction to create sky-projected aligned super-sky metric
  results.spa_ssmetric = results.a_ssmetric;
  results.spa_ssmetric(inc, :) = results.spa_ssmetric(:, inc) = [];

  ## determine indices of sky-projected aligned super-sky metric coordinates
  assert(ina < inc);
  assert(inb < inc);
  spa_iff = iff;
  spa_iff(spa_iff > inc) -= 1;

  ## diagonally normalise sky-projected aligned metric
  [D_spa_ssmetric, DN_spa_ssmetric] = DiagonalNormaliseMetric(results.spa_ssmetric);

  ## compute Cholesky decomposition of diagonally-normalised sky-projected aligned metric
  CD_spa_ssmetric = chol(D_spa_ssmetric);

  ## compute transform from surface of unit sphere to surface of sky-projected aligned
  ## metric ellipsoid with maximum mismatch of 'max_mismatch'
  onto_spa_ssmetric = sqrt(max_mismatch) * DN_spa_ssmetric * inv(CD_spa_ssmetric);

  ## build error histogram dimensionality and bin types
  H_args = {3, ...
            {"lin", "dbin", 2*pi/15}, ...			## right ascension
            {"lin", "dbin", pi/15}, ...				## declination
            {"log", "minrange", 0.01, "binsper10", 5}, ...	## mismatch
            };

  ## initialise result histograms
  results.mu_spa_ssmetric_H = Hist(H_args{:});
  results.mu_a_ssmetric_H = Hist(H_args{:});
  results.mu_ssmetric_lpI_H = Hist(H_args{:});
  results.mu_ssmetric_lpII_H = Hist(H_args{:});
  results.mu_ssmetric_ad_H = Hist(H_args{:});
  if full_injections
    results.mu_twoF_H = Hist(H_args{:});
  endif

  ## start CPU seconds counter
  cputime0 = cputime();

  ## iterate over all injections, or as long as CPU second limit allows
  while num_injections > 0 && num_cpu_seconds > (cputime() - cputime0)
    if injection_block > num_injections
      injection_block = num_injections;
    endif
    num_injections -= injection_block;

    ## create random point offsets on unit sphere surface
    spa_dp = randn(size(results.spa_ssmetric, 1), injection_block);
    N_spa_dp = norm(spa_dp, "cols");
    for i = 1:size(spa_dp, 1)
      spa_dp(i, :) ./= N_spa_dp;
    endfor

    ## transform point offsets to surface of sky-projected aligned
    ## metric ellipsoid with maximum mismatch of 'max_mismatch'
    spa_dp = onto_spa_ssmetric * spa_dp;

    ## compute mismatch in sky-projected aligned metric
    mu_spa_ssmetric = dot(spa_dp, results.spa_ssmetric * spa_dp);

    ## create random point in unit disk
    r = rand(1, injection_block);
    th = rand(1, injection_block) * 2*pi;
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
    a_dp = zeros(size(results.a_ssmetric, 1), injection_block);
    a_dp([ina, inb, inc], :) = a_n2 - a_n1;
    a_dp(iff, :) = spa_dp(spa_iff, :);

    ## compute mismatch in aligned metric
    mu_a_ssmetric = dot(a_dp, results.a_ssmetric * a_dp);

    ## compute inverse coordinate transform from aligned (residual) coordinates to untransformed super-sky coordinates
    n1 = results.a_alignsky \ a_n1;
    n2 = results.a_alignsky \ a_n2;
    dp = zeros(size(a_dp));
    dp([ina, inb, inc], :) = n2 - n1;
    dp(iff, :) = a_dp(iff, :) - results.a_skyoff * a_dp([ina, inb, inc], :);

    ## compute mismatch in untransformed metric
    mu_ssmetric = dot(dp, results.ssmetric * dp);

    ## compute mismatch in metric with linear phase model I
    mu_ssmetric_lpI = dot(dp, results.ssmetric_lpI * dp);

    ## compute mismatch in metric with linear phase model II
    mu_ssmetric_lpII = dot(dp, results.ssmetric_lpII * dp);

    ## compute right ascensions alpha1 and alpha2 from sky positions n1 and n2
    alpha1 = atan2(n1(2, :), n1(1, :));
    alpha2 = atan2(n2(2, :), n2(1, :));

    ## compute declinations delta1 and delta2 from sky positions n1 and n2,
    ## projected onto upper sky hemisphere
    delta1 = abs(atan2(n1(3, :), sqrt(sumsq(n1(1:2, :)))));
    delta2 = abs(atan2(n2(3, :), sqrt(sumsq(n2(1:2, :)))));

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

    if full_injections

      ## iterate over full software injections
      mu_twoF = zeros(1, injection_block);
      for n = 1:injection_block

        ## set up injection and search parameters
        inj_alpha = alpha1(n);
        inj_delta = delta1(n);
        inj_fndot = [fiducial_freq; zeros(spindowns, 1)];
        sch_alpha = [inj_alpha, inj_alpha + dalpha(n)];
        sch_delta = [inj_delta, inj_delta + ddelta(n)];
        sch_fndot = [inj_fndot, inj_fndot + dp(iff, n)];

        ## perform software injections in generated SFTs
        inj_results = DoFstatInjections("ref_time", ref_time,
                                        "start_time", start_time,
                                        "time_span", time_span,
                                        "detectors", detectors,
                                        "ephemerides", ephemerides,
                                        "inj_alpha", inj_alpha,
                                        "inj_delta", inj_delta,
                                        "inj_fndot", inj_fndot,
                                        "sch_alpha", sch_alpha,
                                        "sch_delta", sch_delta,
                                        "sch_fndot", sch_fndot);

        ## get 2F values for perfect and mismatched injections
        assert(length(inj_results.sch_twoF) == 2);
        twoF_perfect = inj_results.sch_twoF(1);
        twoF_mismatch = inj_results.sch_twoF(2);

        ## compute mismatch using injections
        mu_twoF(n) = (twoF_perfect - twoF_mismatch) ./ (twoF_perfect - 4);

      endfor

    endif

    ## build error histogram parameters
    H_par = [alpha1(:), delta1(:)];

    ## bin error in sky-projected aligned mismatch compared to untransformed mismatch
    mu_spa_ssmetric_err = mu_spa_ssmetric ./ mu_ssmetric - 1;
    results.mu_spa_ssmetric_H = addDataToHist(results.mu_spa_ssmetric_H, [H_par, mu_spa_ssmetric_err(:)]);

    ## bin error in aligned mismatch compared to untransformed mismatch
    mu_a_ssmetric_err = mu_a_ssmetric ./ mu_ssmetric - 1;
    results.mu_a_ssmetric_H = addDataToHist(results.mu_a_ssmetric_H, [H_par, mu_a_ssmetric_err(:)]);

    ## bin error in linear phase model I metric compared to untransformed mismatch
    mu_ssmetric_lpI_err = mu_ssmetric_lpI ./ mu_ssmetric - 1;
    results.mu_ssmetric_lpI_H = addDataToHist(results.mu_ssmetric_lpI_H, [H_par, mu_ssmetric_lpI_err(:)]);

    ## bin error in linear phase model II metric compared to untransformed mismatch
    mu_ssmetric_lpII_err = mu_ssmetric_lpII ./ mu_ssmetric - 1;
    results.mu_ssmetric_lpII_H = addDataToHist(results.mu_ssmetric_lpII_H, [H_par, mu_ssmetric_lpII_err(:)]);

    ## bin error in metric using physical coordinates compared to untransformed mismatch
    mu_ssmetric_ad_err = mu_ssmetric_ad ./ mu_ssmetric - 1;
    results.mu_ssmetric_ad_H = addDataToHist(results.mu_ssmetric_ad_H, [H_par, mu_ssmetric_ad_err(:)]);

    if full_injections

      ## bin error in full software injections mismatch compared to untransformed mismatch
      mu_twoF_err = mu_twoF ./ mu_ssmetric - 1;
      results.mu_twoF_H = addDataToHist(results.mu_twoF_H, [H_par, mu_twoF_err(:)]);

    endif

  endwhile

endfunction
