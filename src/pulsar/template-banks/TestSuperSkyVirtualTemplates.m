## Copyright (C) 2014 Karl Wette
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

## Test the super-sky metric using a 'virtual' lattice template bank,
## and (optionally) with full software injections.
## Usage:
##   results = TestSuperSkyVirtualTemplates("opt", val, ...)
## Options:
##   spindowns:       number of frequency spindowns coordinates
##   start_time:      start time in GPS seconds
##   ref_time:        reference time in GPS seconds
##   time_span:       observation time-span in seconds
##   detectors:       comma-separated list of detector names
##   ephemerides:     Earth/Sun ephemerides from loadEphemerides()
##   fiducial_freq:   fiducial frequency at which to perform tests
##   max_mismatch:    maximum prescribed mismatch to test at
##   lattice:         lattice to use in constructing virtual templates (default: Ans)
##   num_injections:  number of injections to perform
##   full_injections: whether to perform full software injections (default: true)
##   injection_block: number of injections to perform at once (default: 100)
## Results struct contains arrays:
##   mu_rss_metric:   mismatch w.r.t reduced super-sky metric
##   mu_ss_metric:    mismatch w.r.t un-transformed super-sky metric
##   mu_twoF:         mismatch w.r.t 2F computed using full software injections (if full_injections==true)
##   alpha1, alpha2:  right ascensions of simulated template pairs
##   delta1, delta2:  declinations of simulated template pairs
##   dfndot:          frequency/spindown offsets of simulated template pairs

function results = TestSuperSkyVirtualTemplates(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## load constants
  UnitsConstants;

  ## parse options
  parseOptions(varargin,
               {"spindowns", "integer,positive,scalar"},
               {"start_time", "real,strictpos,scalar"},
               {"ref_time", "real,strictpos,scalar"},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephemerides", "a:swig_ref", []},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"max_mismatch", "real,strictpos,scalar", 0.5},
               {"lattice", "char", "Ans"},
               {"num_injections", "integer,strictpos,scalar", 1},
               {"full_injections", "logical,scalar", true},
               {"injection_block", "integer,strictpos,scalar", 50000},
               []);

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## create spin-orbit component metric, and construct super-sky metrics
  [sometric, socoordIDs] = ...
      CreatePhaseMetric("coords", "spin_equ,orbit_ecl,freq,fdots",
                        "spindowns", spindowns,
                        "start_time", start_time,
                        "ref_time", ref_time,
                        "time_span", time_span,
                        "detectors", detectors,
                        "ephemerides", ephemerides,
                        "fiducial_freq", fiducial_freq,
                        "det_motion", "spin+orbit");
  ssm_equ = ConstructSuperSkyMetrics(sometric, socoordIDs, "sky_coords", "equatorial", "aligned_sky", true);

  ## untransformed super-sky metric and coordinate indices
  ss_metric = ssm_equ.ssmetric;
  ss_inx = find(ssm_equ.sscoordIDs == DOPPLERCOORD_N3X_EQU);
  ss_iny = find(ssm_equ.sscoordIDs == DOPPLERCOORD_N3Y_EQU);
  ss_inz = find(ssm_equ.sscoordIDs == DOPPLERCOORD_N3Z_EQU);
  ss_iff = [find(ssm_equ.sscoordIDs == DOPPLERCOORD_FREQ), ...
            find(ssm_equ.sscoordIDs == DOPPLERCOORD_F1DOT), ...
            find(ssm_equ.sscoordIDs == DOPPLERCOORD_F2DOT), ...
            find(ssm_equ.sscoordIDs == DOPPLERCOORD_F3DOT)];

  ## reduced super-sky metric and coordinate indices
  assert(ss_inx < ss_inz);
  assert(ss_iny < ss_inz);
  rss_metric = ssm_equ.assmetric;
  rss_metric(ss_inz, :) = rss_metric(:, ss_inz) = [];
  rss_ina = ss_inx;
  rss_inb = ss_iny;
  rss_iff = ss_iff;
  rss_iff(rss_iff > ss_inz) -= 1;

  ## transformation matrices from reduced super-sky back to untransform super-sky
  rss_skyoff = ssm_equ.askyoff;
  rss_alignsky = ssm_equ.alignsky;

  ## bounding box of reduced super-sky metric, used when generating random points
  rss_boundbox = diag(metricBoundingBox(rss_metric, max_mismatch));

  ## initialise results struct
  results = struct;
  results.mu_rss_metric = nan(1, num_injections);
  results.mu_ss_metric = nan(1, num_injections);
  if full_injections
    results.mu_twoF = nan(1, num_injections);
  endif
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

    ## create random point in sky (unit disk), frequency (rand/T),
    ## and spindowns (rand/T^s, s spindown order), where T is observation time
    rss_x1 = zeros(spindowns+3, injection_block);
    rss_x1([rss_ina, rss_inb], :) = randPointInNSphere(2, rand(1, injection_block));
    rss_x1(rss_iff, :) = rss_boundbox(rss_iff, rss_iff) * rand(spindowns+1, injection_block);

    ## find closest template to each point in a 'virtual' lattice template bank
    rss_x2 = FindClosestTemplate(rss_x1, rss_metric, max_mismatch, lattice);
    rss_dx = rss_x2 - rss_x1;

    ## adjust points so that both are inside sky (unit disk)
    rss_sky_r = norm(rss_x2([rss_ina, rss_inb], :), "cols");
    rss_sky_out = find(rss_sky_r > 1);
    if !isempty(rss_sky_out)
      rss_x2(rss_ina, rss_sky_out) ./= rss_sky_r(rss_sky_out);
      rss_x2(rss_inb, rss_sky_out) ./= rss_sky_r(rss_sky_out);
    endif
    rss_x1 = rss_x2 - rss_dx;

    ## compute mismatch w.r.t reduced super-sky metric
    results.mu_rss_metric(ii) = dot(rss_dx, rss_metric * rss_dx);

    ## project reduced super-sky points onto upper hemisphere, creating difference in aligned super-sky coordinates
    ass_x1 = ass_x2 = zeros(spindowns+4, injection_block);
    ass_x1([ss_inx, ss_iny, ss_iff], :) = rss_x1([rss_ina, rss_inb, rss_iff], :);
    ass_x2([ss_inx, ss_iny, ss_iff], :) = rss_x2([rss_ina, rss_inb, rss_iff], :);
    ass_x1(ss_inz, :) = real(sqrt(1 - sumsq(rss_x1([rss_ina, rss_inb], :))));
    ass_x2(ss_inz, :) = real(sqrt(1 - sumsq(rss_x2([rss_ina, rss_inb], :))));

    ## compute inverse coordinate transform from aligned super-sky coordinates to un-transformed super-sky coordinates
    ss_x1 = ss_x2 = zeros(spindowns+4, injection_block);
    ss_x1([ss_inx, ss_iny, ss_inz], :) = rss_alignsky \ ass_x1([ss_inx, ss_iny, ss_inz], :);
    ss_x2([ss_inx, ss_iny, ss_inz], :) = rss_alignsky \ ass_x2([ss_inx, ss_iny, ss_inz], :);
    ss_x1(ss_iff, :) = ass_x1(ss_iff, :) - rss_skyoff * ass_x1([ss_inx, ss_iny, ss_inz], :);
    ss_x2(ss_iff, :) = ass_x2(ss_iff, :) - rss_skyoff * ass_x2([ss_inx, ss_iny, ss_inz], :);
    ss_dx = ss_x2 - ss_x1;

    ## compute mismatch w.r.t. un-transformed super-sky metric
    results.mu_ss_metric(ii) = dot(ss_dx, ss_metric * ss_dx);

    ## compute right ascensions alpha1 and alpha2 from super-sky positions
    alpha1 = mod(atan2(ss_x1(ss_iny, :), ss_x1(ss_inx, :)), 2*pi);
    alpha2 = mod(atan2(ss_x2(ss_iny, :), ss_x2(ss_inx, :)), 2*pi);
    results.alpha1(ii) = alpha1;
    results.alpha2(ii) = alpha2;

    ## compute declinations delta1 and delta2 from super-sky positions
    delta1 = atan2(ss_x1(ss_inz, :), sqrt(sumsq(ss_x1([ss_inx, ss_iny], :))));
    delta2 = atan2(ss_x2(ss_inz, :), sqrt(sumsq(ss_x2([ss_inx, ss_iny], :))));
    results.delta1(ii) = delta1;
    results.delta2(ii) = delta2;

    ## compute injection and offset frequencies
    fndot1 = ss_x1(ss_iff, :);
    fndot2 = ss_x2(ss_iff, :);
    fndot1(1, :) += fiducial_freq;
    fndot2(1, :) += fiducial_freq;
    results.dfndot(:, ii) = fndot2 - fndot1;

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

    endif

  endwhile

endfunction
