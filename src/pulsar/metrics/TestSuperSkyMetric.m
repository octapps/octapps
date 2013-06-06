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
##     sometric           = spin-orbit-decoupled super-sky metric
##     ssmetric           = super-sky metric
##     d_ssmetric_equ     = sky-projected unaligned super-sky metric in equatorial coordinates
##     d_ssmetric_equ     = sky-projected unaligned super-sky metric in ecliptic coordinates
##     a_ssmetric         = aligned super-sky metric
##     ssmetric_lpI       = super-sky metric computed with JKS's linear I phase model
##     ssmetric_lpII      = super-sky metric computed with JKS's linear II phase model
##     gct_taylor_metric  = GCT Taylor-expanded metric computed by GCTCoherentTaylorMetric()
##   mismatch error histograms, with respect to untransformed mismatch:
##     mu_spa_ssmetric_H     = error in sky-projected aligned mismatch
##     mu_spd_ssmetric_equ_H = error in sky-projected un-aligned equatorial mismatch
##     mu_spd_ssmetric_ecl_H = error in sky-projected un-aligned ecliptic mismatch
##     mu_d_ssmetric_equ_H   = error in un-aligned equatorial mismatch
##     mu_d_ssmetric_ecl_H   = error in un-aligned ecliptic mismatch
##     mu_a_ssmetric_H       = error in aligned mismatch compared to untransformed mismatch
##     mu_ssmetric_lpI_H     = error in linear phase model I metric compared to untransformed mismatch
##     mu_ssmetric_lpII_H    = error in linear phase model II metric compared to untransformed mismatch
##     mu_ssmetric_ad_H      = error in mismatch using physical coordinates compared to untransformed mismatch
##     mu_gct_taylor_H       = error in mismatch using GCT Taylor-expanded metric computed by GCTCoherentTaylorMetric()
##     mu_gct_full_H         = error in mismatch using GCT full metric computed by GCTCoherentFullMetric()
##     mu_twoF_H             = (optional) error in full software injections mismatch compared to untransformed mismatch
## Options:
##   spindowns: number of frequency spindowns coordinates
##   start_time: start time in GPS seconds (default: see CreatePhaseMetric)
##   ref_time: reference time in GPS seconds (default: see CreatePhaseMetric)
##   time_span: observation time-span in seconds
##   detectors: comma-separated list of detector names
##   ephemerides: Earth/Sun ephemerides from loadEphemerides()
##   fiducial_freq: fiducial frequency at which to perform tests
##   max_mismatch: maximum prescribed mismatch to test at
##   num_injections: number of injections to perform
##   num_cpu_seconds: number of CPU seconds to perform injections for
##   full_injections: whether to perform full software injections (default: true)
##   injection_block: number of injections to perform at once (default: 100)
##   ptolemaic: use Ptolemaic orbital motion

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
               {"max_mismatch", "real,strictpos,scalar", 0.5},
               {"num_injections", "integer,strictpos,scalar", inf},
               {"num_cpu_seconds", "real,strictpos,scalar", inf},
               {"full_injections", "logical,scalar", true},
               {"injection_block", "integer,strictpos,scalar", 100},
               {"ptolemaic", "logical,scalar", false},
               []);
  if !xor(isfinite(num_injections), isfinite(num_cpu_seconds))
    error("%s: must give either num_injections or num_cpu_seconds", funcName);
  endif

  ## load ephemerides if needed and not supplied
  if !ptolemaic && isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## create ptolemaic detector motion string
  if ptolemaic
    ptole = "ptole";
  else
    ptole = "";
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
                        "det_motion", sprintf("spin+%sorbit", ptole));

  ## construct untransformed super-sky metric
  [results.ssmetric, _, _, sscoordIDs] = ...
      ConstructSuperSkyMetrics(results.sometric, socoordIDs, "sky_coords", "equatorial");

  ## determine indices of super-sky metric coordinates
  ina = find(sscoordIDs == DOPPLERCOORD_N3X_EQU | sscoordIDs == DOPPLERCOORD_N3X_ECL);
  inb = find(sscoordIDs == DOPPLERCOORD_N3Y_EQU | sscoordIDs == DOPPLERCOORD_N3Y_ECL);
  inc = find(sscoordIDs == DOPPLERCOORD_N3Z_EQU | sscoordIDs == DOPPLERCOORD_N3Z_ECL);
  iff = [find(sscoordIDs == DOPPLERCOORD_FREQ), ...
         find(sscoordIDs == DOPPLERCOORD_F1DOT), ...
         find(sscoordIDs == DOPPLERCOORD_F2DOT), ...
         find(sscoordIDs == DOPPLERCOORD_F3DOT)];

  ## construct un-aligned decoupled super-sky metrics
  [results.d_ssmetric_equ, d_skyoff_equ, d_alignsky_equ, d_sscoordIDs_equ] = ...
      ConstructSuperSkyMetrics(results.sometric, socoordIDs, "sky_coords", "equatorial", "decouple_sky", true);
  assert(all(d_sscoordIDs_equ == sscoordIDs));
  [results.d_ssmetric_ecl, d_skyoff_ecl, d_alignsky_ecl] = ...
      ConstructSuperSkyMetrics(results.sometric, socoordIDs, "sky_coords", "ecliptic", "decouple_sky", true);

  ## construct aligned super-sky metric
  [results.a_ssmetric, a_skyoff, a_alignsky, a_sscoordIDs] = ...
      ConstructSuperSkyMetrics(results.sometric, socoordIDs, "sky_coords", "equatorial", "aligned_sky", true);
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
                        "det_motion", sprintf("spinxy+%sorbit", ptole));
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
                        "det_motion", sprintf("%sorbit", ptole));
  assert(all(sscoordIDs_lpII == sscoordIDs));

  ## determine indices of sky-projected super-sky metric coordinates
  assert(ina < inc);
  assert(inb < inc);
  sp_iff = iff;
  sp_iff(sp_iff > inc) -= 1;

  ## create sky-projected aligned super-sky metric by removing aligned-c direction
  spa_ssmetric = results.a_ssmetric;
  spa_ssmetric(inc, :) = spa_ssmetric(:, inc) = [];

  ## create sky-projected un-aligned decoupled super-sky metrics by zeroing equatorial/ecliptic-z directions
  spd_ssmetric_equ = results.d_ssmetric_equ;
  spd_ssmetric_equ(inc, :) = spd_ssmetric_equ(:, inc) = 0;
  spd_ssmetric_ecl = results.d_ssmetric_ecl;
  spd_ssmetric_ecl(inc, :) = spd_ssmetric_ecl(:, inc) = 0;

  ## diagonally normalise sky-projected aligned metric
  [D_spa_ssmetric, DN_spa_ssmetric] = DiagonalNormaliseMetric(spa_ssmetric);

  ## compute Cholesky decomposition of diagonally-normalised sky-projected aligned metric
  CD_spa_ssmetric = chol(D_spa_ssmetric);

  ## compute transform from surface of unit sphere to surface of sky-projected aligned
  ## metric ellipsoid with maximum mismatch of 'max_mismatch'
  onto_spa_ssmetric = sqrt(max_mismatch) * DN_spa_ssmetric * inv(CD_spa_ssmetric);

  ## compute the GCT coherent metric, if possible (spindowns <= 2 and only one detector)
  compute_gct = spindowns <= 2 && isempty(strfind(detectors, ","));
  if compute_gct
    results.gct_taylor_metric = GCTCoherentTaylorMetric("smax", spindowns,
                                                        "tj", start_time + 0.5 * time_span,
                                                        "t0", ref_time,
                                                        "T", time_span);
    gct_full_metric_cache = [];
  else
    fprintf("%s: not computing the GCT metric (spindowns=%i, detectors='%s')\n", funcName, spindowns, detectors);
  endif

  ## build error histogram dimensionality and bin types
  H_args = {3, ...
            {"log", "minrange", 0.01, "binsper10", 5}, ...	## mismatch
            {"lin", "dbin", 2*pi/15}, ...			## right ascension
            {"lin", "dbin", pi/15}, ...				## declination
            };

  ## initialise result histograms
  results.mu_spa_ssmetric_H = Hist(H_args{:});
  results.mu_spd_ssmetric_equ_H = Hist(H_args{:});
  results.mu_spd_ssmetric_ecl_H = Hist(H_args{:});
  results.mu_d_ssmetric_equ_H = Hist(H_args{:});
  results.mu_d_ssmetric_ecl_H = Hist(H_args{:});
  results.mu_a_ssmetric_H = Hist(H_args{:});
  results.mu_ssmetric_lpI_H = Hist(H_args{:});
  results.mu_ssmetric_lpII_H = Hist(H_args{:});
  results.mu_ssmetric_ad_H = Hist(H_args{:});
  if compute_gct
    results.mu_gct_taylor_H = Hist(H_args{:});
    results.mu_gct_full_H = Hist(H_args{:});
  endif
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
    spa_dp = randn(size(spa_ssmetric, 1), injection_block);
    N_spa_dp = norm(spa_dp, "cols");
    spa_dp ./= N_spa_dp(ones(1, size(spa_dp, 1)), :);

    ## transform point offsets to surface of sky-projected aligned
    ## metric ellipsoid with maximum mismatch of 'max_mismatch'
    spa_dp = onto_spa_ssmetric * spa_dp;

    ## create random point on surface on unit sphere
    a_n1 = randPointInNSphere(3, rand(1, injection_block));
    x1 = a_n1([1, 2], :);

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

    ## rescale dx and update random offset
    dx .*= c([1, 1], :);
    spa_dp([ina, inb], :) = dx;

    ## compute mismatch in sky-projected aligned metric
    mu_spa_ssmetric = dot(spa_dp, spa_ssmetric * spa_dp);

    ## compute second random point by adding (scaled) offset
    x2 = x1 + dx;

    ## project second point onto (aligned) sky sphere; place in same hemisphere as first random point,
    ## use real() to calculate 3rd component in case points have radius >1 due to numerical roundoff
    a_n2 = [x2; sign(a_n1(3, :)).*real(sqrt(1 - sumsq(x2)))];

    ## create point offsets in (non-sky-projected) aligned metric
    a_dp = zeros(size(results.a_ssmetric, 1), injection_block);
    a_dp([ina, inb, inc], :) = a_n2 - a_n1;
    a_dp(iff, :) = spa_dp(sp_iff, :);

    ## compute mismatch in aligned metric
    mu_a_ssmetric = dot(a_dp, results.a_ssmetric * a_dp);

    ## compute inverse coordinate transform from aligned coordinates to untransformed super-sky coordinates
    n1_equ = a_alignsky \ a_n1;
    n2_equ = a_alignsky \ a_n2;
    dp = zeros(size(a_dp));
    dp([ina, inb, inc], :) = n2_equ - n1_equ;
    dp(iff, :) = a_dp(iff, :) - a_skyoff * a_dp([ina, inb, inc], :);

    ## compute mismatch in untransformed metric
    mu_ssmetric = dot(dp, results.ssmetric * dp);

    ## compute coordinate transform from untransformed to un-aligned decoupled equatorial super-sky coordinates
    d_n1_equ = d_alignsky_equ * n1_equ;
    d_n2_equ = d_alignsky_equ * n2_equ;
    d_dp_equ = zeros(size(dp));
    d_dp_equ([ina, inb, inc], :) = d_n2_equ - d_n1_equ;
    d_dp_equ(iff, :) = dp(iff, :) + d_skyoff_equ * d_dp_equ([ina, inb, inc], :);

    ## compute mismatch in (sky-projected) un-aligned decoupled equatorial metric
    mu_d_ssmetric_equ = dot(d_dp_equ, results.d_ssmetric_equ * d_dp_equ);
    mu_spd_ssmetric_equ = dot(d_dp_equ, spd_ssmetric_equ * d_dp_equ);

    ## convert sky position points from equatorial to ecliptic coordinates
    n1_ecl = [n1_equ(1,:); n1_equ(2,:)*LAL_COSIEARTH + n1_equ(3,:)*LAL_SINIEARTH; n1_equ(3,:)*LAL_COSIEARTH - n1_equ(2,:)*LAL_SINIEARTH];
    n2_ecl = [n2_equ(1,:); n2_equ(2,:)*LAL_COSIEARTH + n2_equ(3,:)*LAL_SINIEARTH; n2_equ(3,:)*LAL_COSIEARTH - n2_equ(2,:)*LAL_SINIEARTH];

    ## compute coordinate transform from untransformed to un-aligned decoupled ecliptic super-sky coordinates
    d_n1_ecl = d_alignsky_ecl * n1_ecl;
    d_n2_ecl = d_alignsky_ecl * n2_ecl;
    d_dp_ecl = zeros(size(dp));
    d_dp_ecl([ina, inb, inc], :) = d_n2_ecl - d_n1_ecl;
    d_dp_ecl(iff, :) = dp(iff, :) + d_skyoff_ecl * d_dp_ecl([ina, inb, inc], :);

    ## compute mismatch in (sky-projected) un-aligned decoupled ecliptic metric
    mu_d_ssmetric_ecl = dot(d_dp_ecl, results.d_ssmetric_ecl * d_dp_ecl);
    mu_spd_ssmetric_ecl = dot(d_dp_ecl, spd_ssmetric_ecl * d_dp_ecl);

    ## compute mismatch in metric with linear phase model I
    mu_ssmetric_lpI = dot(dp, results.ssmetric_lpI * dp);

    ## compute mismatch in metric with linear phase model II
    mu_ssmetric_lpII = dot(dp, results.ssmetric_lpII * dp);

    ## compute right ascensions alpha1 and alpha2 from sky positions n1_equ and n2_equ
    alpha1 = atan2(n1_equ(2, :), n1_equ(1, :));
    alpha2 = atan2(n2_equ(2, :), n2_equ(1, :));

    ## compute declinations delta1 and delta2 from sky positions n1_equ and n2_equ
    delta1 = atan2(n1_equ(3, :), sqrt(sumsq(n1_equ(1:2, :))));
    delta2 = atan2(n2_equ(3, :), sqrt(sumsq(n2_equ(1:2, :))));

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

    if compute_gct

      ## frequency points for computing GCT coordinates
      gct_fndot1 = [fiducial_freq*ones(1, injection_block); zeros(spindowns, injection_block)];
      gct_fndot2 = gct_fndot1 + dp(iff, :);

      ## compute GCT coordinates
      gct_coord1 = GCTCoordinates("t0", ref_time,
                                  "T", time_span,
                                  "alpha", alpha1,
                                  "delta", delta1,
                                  "fndot", gct_fndot1,
                                  "detector", detectors,
                                  "ephemerides", ephemerides,
                                  "ptolemaic", ptolemaic);
      gct_coord2 = GCTCoordinates("t0", ref_time,
                                  "T", time_span,
                                  "alpha", alpha2,
                                  "delta", delta2,
                                  "fndot", gct_fndot2,
                                  "detector", detectors,
                                  "ephemerides", ephemerides,
                                  "ptolemaic", ptolemaic);

      ## compute mismatch in the Taylor-expanded GCT metric
      gct_dcoord = gct_coord2 - gct_coord1;
      mu_gct_taylor = dot(gct_dcoord, results.gct_taylor_metric * gct_dcoord);

      ## compute the full GCT metric
      gct_full_metric = GCTCoherentFullMetric(gct_full_metric_cache,
                                              "smax", spindowns,
                                              "tj", start_time + 0.5 * time_span,
                                              "t0", ref_time,
                                              "T", time_span,
                                              "alpha", alpha1,
                                              "delta", delta1,
                                              "detector", detectors,
                                              "ephemerides", ephemerides,
                                              "ptolemaic", ptolemaic);

      ## compute mismatch in the full GCT metric
      mu_gct_full = arrayfun(@(n) dot(gct_dcoord(:, n), gct_full_metric(:, :, n) * gct_dcoord(:, n)), 1:injection_block);

    endif

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

      ## change any NaNs to Infs
      mu_twoF(isnan(mu_twoF)) = inf;

    endif

    ## build error histogram parameters
    H_par = [alpha1(:), delta1(:)];

    ## bin error in sky-projected aligned mismatch compared to untransformed super-sky mismatch
    mu_spa_ssmetric_err = mu_spa_ssmetric ./ mu_ssmetric - 1;
    results.mu_spa_ssmetric_H = addDataToHist(results.mu_spa_ssmetric_H, [mu_spa_ssmetric_err(:), H_par]);

    ## bin error in sky-projected un-aligned decoupled equatorial mismatch compared to untransformed super-sky mismatch
    mu_spd_ssmetric_equ_err = mu_spd_ssmetric_equ ./ mu_ssmetric - 1;
    results.mu_spd_ssmetric_equ_H = addDataToHist(results.mu_spd_ssmetric_equ_H, [mu_spd_ssmetric_equ_err(:), H_par]);

    ## bin error in sky-projected un-aligned decoupled ecliptic mismatch compared to untransformed super-sky mismatch
    mu_spd_ssmetric_ecl_err = mu_spd_ssmetric_ecl ./ mu_ssmetric - 1;
    results.mu_spd_ssmetric_ecl_H = addDataToHist(results.mu_spd_ssmetric_ecl_H, [mu_spd_ssmetric_ecl_err(:), H_par]);

    ## bin error in un-aligned decoupled equatorial mismatch compared to untransformed super-sky mismatch
    mu_d_ssmetric_equ_err = mu_d_ssmetric_equ ./ mu_ssmetric - 1;
    results.mu_d_ssmetric_equ_H = addDataToHist(results.mu_d_ssmetric_equ_H, [mu_d_ssmetric_equ_err(:), H_par]);

    ## bin error in un-aligned decoupled ecliptic mismatch compared to untransformed super-sky mismatch
    mu_d_ssmetric_ecl_err = mu_d_ssmetric_ecl ./ mu_ssmetric - 1;
    results.mu_d_ssmetric_ecl_H = addDataToHist(results.mu_d_ssmetric_ecl_H, [mu_d_ssmetric_ecl_err(:), H_par]);

    ## bin error in aligned mismatch compared to untransformed super-sky mismatch
    mu_a_ssmetric_err = mu_a_ssmetric ./ mu_ssmetric - 1;
    results.mu_a_ssmetric_H = addDataToHist(results.mu_a_ssmetric_H, [mu_a_ssmetric_err(:), H_par]);

    ## bin error in linear phase model I mismatch compared to untransformed super-sky mismatch
    mu_ssmetric_lpI_err = mu_ssmetric_lpI ./ mu_ssmetric - 1;
    results.mu_ssmetric_lpI_H = addDataToHist(results.mu_ssmetric_lpI_H, [mu_ssmetric_lpI_err(:), H_par]);

    ## bin error in linear phase model II mismatch compared to untransformed super-sky mismatch
    mu_ssmetric_lpII_err = mu_ssmetric_lpII ./ mu_ssmetric - 1;
    results.mu_ssmetric_lpII_H = addDataToHist(results.mu_ssmetric_lpII_H, [mu_ssmetric_lpII_err(:), H_par]);

    ## bin error in mismatch using physical coordinates compared to untransformed super-sky mismatch
    mu_ssmetric_ad_err = mu_ssmetric_ad ./ mu_ssmetric - 1;
    results.mu_ssmetric_ad_H = addDataToHist(results.mu_ssmetric_ad_H, [mu_ssmetric_ad_err(:), H_par]);

    if compute_gct

      ## bin error in mismatch in the Taylor-expanded GCT metric compared to untransformed super-sky mismatch
      mu_gct_taylor_err = mu_gct_taylor ./ mu_ssmetric - 1;
      results.mu_gct_taylor_H = addDataToHist(results.mu_gct_taylor_H, [mu_gct_taylor_err(:), H_par]);

      ## bin error in mismatch in the full GCT metric compared to untransformed super-sky mismatch
      mu_gct_full_err = mu_gct_full ./ mu_ssmetric - 1;
      results.mu_gct_full_H = addDataToHist(results.mu_gct_full_H, [mu_gct_full_err(:), H_par]);

    endif

    if full_injections

      ## bin error in full software injections mismatch compared to untransformed super-sky mismatch
      mu_twoF_err = mu_twoF ./ mu_ssmetric - 1;
      results.mu_twoF_H = addDataToHist(results.mu_twoF_H, [mu_twoF_err(:), H_par]);

    endif

  endwhile

endfunction
