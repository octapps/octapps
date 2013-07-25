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
## Options:
##   spindowns:       number of frequency spindowns coordinates
##   start_time:      start time in GPS seconds (default: see CreatePhaseMetric)
##   ref_time:        reference time in GPS seconds (default: see CreatePhaseMetric)
##   time_span:       observation time-span in seconds
##   detectors:       comma-separated list of detector names
##   ephemerides:     Earth/Sun ephemerides from loadEphemerides()
##   fiducial_freq:   fiducial frequency at which to perform tests
##   max_mismatch:    maximum prescribed mismatch to test at
##   num_injections:  number of injections to perform
##   full_injections: whether to perform full software injections (default: true)
##   gct_injections:  whether to perform GCT injections (default: true for spindowns <= 2 and detectors <= 1)
##   injection_block: number of injections to perform at once (default: 100)
##   ptolemaic:       use Ptolemaic orbital motion (default: false)
## Results struct contains sub-structures:
##   <mismatch>_wrt_<ref_mismatch>_err
## where <mismatch> can be mismatch computed using:
##   spa_ssmetric:     sky-projected aligned super-sky metric
##   spd_ssmetric_equ: sky-projected un-aligned equatorial super-sky metric
##   spd_ssmetric_ecl: sky-projected un-aligned ecliptic super-sky metric
##   d_ssmetric_equ:   un-aligned equatorial super-sky metric
##   d_ssmetric_ecl:   un-aligned ecliptic super-sky metric
##   a_ssmetric:       aligned super-sky metric
##   ssmetric_lpI:     super-sky metric using linear phase model I
##   ssmetric_lpII:    super-sky metric using linear phase model II
##   ssmetric_ad:      super-sky metric using right ascension and declination as sky coordinates
##   gct_taylor:       GCT Taylor-expanded metric computed by GCTCoherentTaylorMetric()
##   gct_full:         GCT full metric computed by GCTCoherentFullMetric()
## and <mismatch_ref> can be mismatch computed using:
##   ssmetric:         un-transformed super-sky metric
##   twoF:             2F computed using full software injections

function results = TestSuperSkyMetric(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## load constants
  UnitsConstants;

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
               {"full_injections", "logical,scalar", true},
               {"gct_injections", "logical,scalar", []},
               {"injection_block", "integer,strictpos,scalar", 100},
               {"ptolemaic", "logical,scalar", false},
               []);

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
  [sometric, socoordIDs, start_time, ref_time] = ...
      CreatePhaseMetric("coords", "spin_equ,orbit_ecl,freq,fdots",
                        "spindowns", spindowns,
                        "start_time", start_time,
                        "ref_time", ref_time,
                        "time_span", time_span,
                        "detectors", detectors,
                        "ephemerides", ephemerides,
                        "fiducial_freq", fiducial_freq,
                        "det_motion", sprintf("spin+%sorbit", ptole));

  ## construct super-sky metrics
  ssm_equ = ConstructSuperSkyMetrics(sometric, socoordIDs, "sky_coords", "equatorial", "aligned_sky", true);
  ssm_ecl = ConstructSuperSkyMetrics(sometric, socoordIDs, "sky_coords", "ecliptic", "aligned_sky", true);
  ssmetric = ssm_equ.ssmetric;
  d_ssmetric_equ = ssm_equ.dssmetric;
  d_skyoff_equ = ssm_equ.dskyoff;
  d_ssmetric_ecl = ssm_ecl.dssmetric;
  d_skyoff_ecl = ssm_ecl.dskyoff;
  a_ssmetric = ssm_equ.assmetric;
  a_skyoff = ssm_equ.askyoff;
  a_alignsky = ssm_equ.alignsky;

  ## determine indices of super-sky metric coordinates
  ina = find(ssm_equ.sscoordIDs == DOPPLERCOORD_N3X_EQU & ssm_ecl.sscoordIDs == DOPPLERCOORD_N3X_ECL);
  inb = find(ssm_equ.sscoordIDs == DOPPLERCOORD_N3Y_EQU & ssm_ecl.sscoordIDs == DOPPLERCOORD_N3Y_ECL);
  inc = find(ssm_equ.sscoordIDs == DOPPLERCOORD_N3Z_EQU & ssm_ecl.sscoordIDs == DOPPLERCOORD_N3Z_ECL);
  iff = [find(ssm_equ.sscoordIDs == DOPPLERCOORD_FREQ), ...
         find(ssm_equ.sscoordIDs == DOPPLERCOORD_F1DOT), ...
         find(ssm_equ.sscoordIDs == DOPPLERCOORD_F2DOT), ...
         find(ssm_equ.sscoordIDs == DOPPLERCOORD_F3DOT)];

  ## create linear phase model metrics from Andrzej Krolak etal's papers
  [ssmetric_lpI, sscoordIDs_lpI] = ...
      CreatePhaseMetric("coords", "ssky_equ,freq,fdots",
                        "spindowns", spindowns,
                        "start_time", start_time,
                        "ref_time", ref_time,
                        "time_span", time_span,
                        "detectors", detectors,
                        "ephemerides", ephemerides,
                        "fiducial_freq", fiducial_freq,
                        "det_motion", sprintf("spinxy+%sorbit", ptole));
  assert(all(sscoordIDs_lpI == ssm_equ.sscoordIDs));
  [ssmetric_lpII, sscoordIDs_lpII] = ...
      CreatePhaseMetric("coords", "ssky_equ,freq,fdots",
                        "spindowns", spindowns,
                        "start_time", start_time,
                        "ref_time", ref_time,
                        "time_span", time_span,
                        "detectors", detectors,
                        "ephemerides", ephemerides,
                        "fiducial_freq", fiducial_freq,
                        "det_motion", sprintf("%sorbit", ptole));
  assert(all(sscoordIDs_lpII == ssm_equ.sscoordIDs));

  ## determine indices of sky-projected super-sky metric coordinates
  assert(ina < inc);
  assert(inb < inc);
  sp_iff = iff;
  sp_iff(sp_iff > inc) -= 1;

  ## create sky-projected aligned super-sky metric by removing aligned-c direction
  spa_ssmetric = a_ssmetric;
  spa_ssmetric(inc, :) = spa_ssmetric(:, inc) = [];

  ## create sky-projected un-aligned decoupled super-sky metrics by zeroing equatorial/ecliptic-z directions
  spd_ssmetric_equ = d_ssmetric_equ;
  spd_ssmetric_equ(inc, :) = spd_ssmetric_equ(:, inc) = 0;
  spd_ssmetric_ecl = d_ssmetric_ecl;
  spd_ssmetric_ecl(inc, :) = spd_ssmetric_ecl(:, inc) = 0;

  ## diagonally normalise sky-projected aligned metric
  [D_spa_ssmetric, DN_spa_ssmetric] = DiagonalNormaliseMetric(spa_ssmetric);

  ## compute Cholesky decomposition of diagonally-normalised sky-projected aligned metric
  CD_spa_ssmetric = chol(D_spa_ssmetric);

  ## compute transform from surface of unit sphere to surface of sky-projected aligned
  ## metric ellipsoid with maximum mismatch of 'max_mismatch'
  onto_spa_ssmetric = sqrt(max_mismatch) * DN_spa_ssmetric * inv(CD_spa_ssmetric);

  ## compute the GCT coherent metric, if asked for and if possible (spindowns <= 2 and only one detector)
  if isempty(gct_injections)
    gct_injections = (spindowns <= 2 && isempty(strfind(detectors, ",")));
  endif
  if gct_injections
    gct_taylor_metric = GCTCoherentTaylorMetric("smax", spindowns,
                                                "tj", start_time + 0.5 * time_span,
                                                "t0", ref_time,
                                                "T", time_span);
    gct_full_metric_cache = [];
  endif

  ## initialise results struct
  results = struct;
  results.mu_spa_ssmetric = nan(1, num_injections);
  results.mu_a_ssmetric = nan(1, num_injections);
  results.mu_ssmetric = nan(1, num_injections);
  results.mu_d_ssmetric_equ = nan(1, num_injections);
  results.mu_spd_ssmetric_equ = nan(1, num_injections);
  results.mu_d_ssmetric_ecl = nan(1, num_injections);
  results.mu_spd_ssmetric_ecl = nan(1, num_injections);
  results.mu_ssmetric_lpI = nan(1, num_injections);
  results.mu_ssmetric_lpII = nan(1, num_injections);
  results.mu_ssmetric_ad = nan(1, num_injections);
  results.mu_gct_taylor = nan(1, num_injections);
  results.mu_gct_full = nan(1, num_injections);
  results.mu_twoF = nan(1, num_injections);
  results.alpha1 = nan(1, num_injections);
  results.alpha2 = nan(1, num_injections);
  results.delta1 = nan(1, num_injections);
  results.delta2 = nan(1, num_injections);
  results.dfndot = nan(spindowns+1, num_injections);

  ## iterate over all injections
  start_injection = 1;
  while start_injection <= num_injections
    end_injection = min(start_injection + injection_block - 1, num_injections);
    ii = start_injection:end_injection;
    injection_block = length(ii);
    start_injection = end_injection + 1;

    ## create random point offsets within unit sphere
    spa_dp = randPointInNSphere(size(spa_ssmetric, 1), rand(1, injection_block));

    ## transform point offsets to surface of sky-projected aligned
    ## metric ellipsoid with maximum mismatch of 'max_mismatch'
    spa_dp = onto_spa_ssmetric * spa_dp;

    ## create random sky point on surface on unit sphere
    a_n1 = randPointInNSphere(3, ones(1, injection_block));
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
    results.mu_spa_ssmetric(ii) = dot(spa_dp, spa_ssmetric * spa_dp);

    ## compute second random point by adding (scaled) offset
    x2 = x1 + dx;

    ## project second point onto (aligned) sky sphere; place in same hemisphere as first random point,
    ## use real() to calculate 3rd component in case points have radius >1 due to numerical roundoff
    a_n2 = [x2; sign(a_n1(3, :)).*real(sqrt(1 - sumsq(x2)))];

    ## create point offsets in (non-sky-projected) aligned metric
    a_dp = zeros(size(a_ssmetric, 1), injection_block);
    a_dp([ina, inb, inc], :) = a_n2 - a_n1;
    a_dp(iff, :) = spa_dp(sp_iff, :);

    ## compute mismatch in aligned metric
    results.mu_a_ssmetric(ii) = dot(a_dp, a_ssmetric * a_dp);

    ## compute inverse coordinate transform from aligned coordinates to un-transformed super-sky coordinates
    n1_equ = a_alignsky \ a_n1;
    n2_equ = a_alignsky \ a_n2;
    dp = zeros(size(a_dp));
    dp([ina, inb, inc], :) = n2_equ - n1_equ;
    dp(iff, :) = a_dp(iff, :) - a_skyoff * a_dp([ina, inb, inc], :);

    ## compute mismatch in un-transformed metric
    results.mu_ssmetric(ii) = dot(dp, ssmetric * dp);

    ## compute coordinate transform from un-transformed to un-aligned decoupled equatorial super-sky coordinates
    d_dp_equ = zeros(size(dp));
    d_dp_equ([ina, inb, inc], :) = n2_equ - n1_equ;
    d_dp_equ(iff, :) = dp(iff, :) + d_skyoff_equ * d_dp_equ([ina, inb, inc], :);

    ## compute mismatch in (sky-projected) un-aligned decoupled equatorial metric
    results.mu_d_ssmetric_equ(ii) = dot(d_dp_equ, d_ssmetric_equ * d_dp_equ);
    results.mu_spd_ssmetric_equ(ii) = dot(d_dp_equ, spd_ssmetric_equ * d_dp_equ);

    ## convert sky position points from equatorial to ecliptic coordinates
    n1_ecl = EQU2ECL * n1_equ;
    n2_ecl = EQU2ECL * n2_equ;

    ## compute coordinate transform from un-transformed to un-aligned decoupled ecliptic super-sky coordinates
    d_dp_ecl = zeros(size(dp));
    d_dp_ecl([ina, inb, inc], :) = n2_ecl - n1_ecl;
    d_dp_ecl(iff, :) = dp(iff, :) + d_skyoff_ecl * d_dp_ecl([ina, inb, inc], :);

    ## compute mismatch in (sky-projected) un-aligned decoupled ecliptic metric
    results.mu_d_ssmetric_ecl(ii) = dot(d_dp_ecl, d_ssmetric_ecl * d_dp_ecl);
    results.mu_spd_ssmetric_ecl(ii) = dot(d_dp_ecl, spd_ssmetric_ecl * d_dp_ecl);

    ## compute mismatch in metric with linear phase model I
    results.mu_ssmetric_lpI(ii) = dot(dp, ssmetric_lpI * dp);

    ## compute mismatch in metric with linear phase model II
    results.mu_ssmetric_lpII(ii) = dot(dp, ssmetric_lpII * dp);

    ## compute right ascensions alpha1 and alpha2 from sky positions n1_equ and n2_equ
    alpha1 = mod(atan2(n1_equ(2, :), n1_equ(1, :)), 2*pi);
    alpha2 = mod(atan2(n2_equ(2, :), n2_equ(1, :)), 2*pi);

    ## compute declinations delta1 and delta2 from sky positions n1_equ and n2_equ
    delta1 = atan2(n1_equ(3, :), sqrt(sumsq(n1_equ(1:2, :))));
    delta2 = atan2(n2_equ(3, :), sqrt(sumsq(n2_equ(1:2, :))));

    ## compute differences in right ascension (accounting for wrap-around) and declination
    dalpha = alpha2 - alpha1;
    dalpha(dalpha > +pi) -= 2*pi;
    dalpha(dalpha < -pi) += 2*pi;
    ddelta = delta2 - delta1;

    ## compute "equivalent" sky position offset in physical coordinates (alpha,delta),
    ## evaluated at (alpha1,delta1). ad_dp is a product of the Jacobian matrix
    ##   \partial(\cos\alpha\cos\delta, \sin\alpha\cos\delta, \sin\delta)/\partial(\alpha,\delta)
    ## and the physical offsets
    ##   (\Delta\alpha, \Delta\delta)
    cosalpha = cos(alpha1);
    sinalpha = sin(alpha1);
    cosdelta = cos(delta1);
    sindelta = sin(delta1);
    ad_dp = dp;
    ad_dp(ina, :) = -sinalpha.*cosdelta.*dalpha - cosalpha.*sindelta.*ddelta;
    ad_dp(inb, :) = cosalpha.*cosdelta.*dalpha - sinalpha.*sindelta.*ddelta;
    ad_dp(inc, :) = cosdelta.*ddelta;

    ## compute mismatch in metric using physical coordinates (alpha,delta)
    results.mu_ssmetric_ad(ii) = dot(ad_dp, ssmetric * ad_dp);

    ## calculate injection and offset frequencies
    fndot1 = [fiducial_freq*ones(1, injection_block); zeros(spindowns, injection_block)];
    fndot2 = fndot1 + dp(iff, :);

    if gct_injections

      ## compute GCT coordinates
      gct_coord1 = GCTCoordinates("t0", ref_time,
                                  "T", time_span,
                                  "alpha", alpha1,
                                  "delta", delta1,
                                  "fndot", fndot1,
                                  "detector", detectors,
                                  "ephemerides", ephemerides,
                                  "ptolemaic", ptolemaic);
      gct_coord2 = GCTCoordinates("t0", ref_time,
                                  "T", time_span,
                                  "alpha", alpha2,
                                  "delta", delta2,
                                  "fndot", fndot2,
                                  "detector", detectors,
                                  "ephemerides", ephemerides,
                                  "ptolemaic", ptolemaic);

      ## compute mismatch in the Taylor-expanded GCT metric
      gct_dcoord = gct_coord2 - gct_coord1;
      results.mu_gct_taylor(ii) = dot(gct_dcoord, gct_taylor_metric * gct_dcoord);

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
      results.mu_gct_full(ii) = arrayfun(@(n) dot(gct_dcoord(:, n), gct_full_metric(:, :, n) * gct_dcoord(:, n)), 1:injection_block);

    endif

    if full_injections

      ## iterate over full software injections
      twoF_perfect = twoF_mismatch = zeros(1, injection_block);
      for n = 1:injection_block

        ## set up injection and search parameters
        inj_alpha = alpha1(n);
        inj_delta = delta1(n);
        inj_fndot = fndot1(:, n);
        sch_alpha = [inj_alpha, alpha2(n)];
        sch_delta = [inj_delta, delta2(n)];
        sch_fndot = [inj_fndot, fndot2(:, n)];

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
        twoF_perfect(n) = inj_results.sch_twoF(1);
        twoF_mismatch(n) = inj_results.sch_twoF(2);

      endfor

      ## compute mismatch using injections
      results.mu_twoF(ii) = (twoF_perfect - twoF_mismatch) ./ (twoF_perfect - 4);

      ## save sky positions and frequency/spindown offsets of injections
      results.alpha1(ii) = alpha1;
      results.alpha2(ii) = alpha2;
      results.delta1(ii) = delta1;
      results.delta2(ii) = delta2;
      results.dfndot(:, ii) = dp(iff, :);

    endif

  endwhile

endfunction
