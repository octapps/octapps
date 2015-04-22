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

## Computes the coherent global correlation transform metric, as
## implemented by LALPulsar/UniversalDopplerMetric, which computes
## the un-Taylor-expanded phase metric in GCT coordinates
## Syntax:
##   [g, gcache] = GCTCoherentFullMetric(gcache, "opt", val, ...)
## where:
##   g      = GCT metric using full phase model, at (alpha,delta)
##   gcache = cached GCT metric using full phase model, independent
##            of (alpha,delta); if [], will be computed and returned
## Options:
##   "smax":        number of spindowns (up to second spindown)
##   "tj":          value of tj, the coherent reference time
##   "t0":          value of t0, an overall reference time
##   "T":           value of T, the coherent time span
##   "alpha":       vector of right ascensions in radians
##   "delta":       vector of declinations in radians
##   "detector":    detector name, e.g. H1
##   "ephemerides": Earth/Sun ephemerides from loadEphemerides()
##   "ptolemaic":   use Ptolemaic orbital motion

function [g, gcache] = GCTCoherentFullMetric(gcache, varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  assert(isempty(gcache) || isstruct(gcache));
  parseOptions(varargin,
               {"smax", "integer,strictpos,scalar"},
               {"tj", "real,scalar"},
               {"t0", "real,scalar"},
               {"T", "real,strictpos,scalar"},
               {"alpha", "real,vector"},
               {"delta", "real,vector"},
               {"detector", "char"},
               {"ephemerides", "a:swig_ref", []},
               {"ptolemaic", "logical,scalar", false},
               []);

  ## check options
  assert(smax <= 2, "Only up to second spindown supported");
  assert(isempty(strfind(detector, ",")), "Only a single detector is supported");
  assert(length(alpha) == length(delta));

  ## stringified list of options which affect calculation of the cached metric
  cache_opts = stringify({smax, tj, t0, T, detector, ptolemaic});

  ## check that cache options match passed options
  if !isempty(gcache)
    gcache
    if !strcmp(gcache.opts, cache_opts)
      error("%s: cached options in 'gcache' do not match passed options!", funcName);
    endif
  endif

  ## get detector information
  multiIFO = new_MultiLALDetector;
  XLALParseMultiLALDetector(multiIFO, XLALCreateStringVector(detector));
  assert(multiIFO.length == 1, "Could not parse detector '%s'", detector);
  detLat = multiIFO.sites{1}.frDetector.vertexLatitudeRadians;
  detLong = multiIFO.sites{1}.frDetector.vertexLongitudeRadians;

  ## get position of GMT at reference time t0
  zeroLong = mod(XLALGreenwichMeanSiderealTime(LIGOTimeGPS(t0)), 2*pi);

  if isempty(gcache)

    ## create cache, save options used to generate metric
    gcache = struct;
    gcache.opts = cache_opts;

    ## create detector motion string
    if ptolemaic
      det_motion = "spin+ptoleorbit";
    else
      det_motion = "spin+orbit";
    endif

    ## compute unconstrained metric in GCT coordinates,
    ## at a fiducial frequency of 1 Hz
    fiducial_freq = 1.0;
    [metric, coordIDs] = CreateDopplerMetric("coords", "gct_nu,ssky_equ",
                                             "spindowns", smax,
                                             "segment_list", [tj - 0.5 * T, tj + 0.5 * T],
                                             "ref_time", t0,
                                             "detectors", detector,
                                             "ephemerides", ephemerides,
                                             "fiducial_freq", fiducial_freq,
                                             "det_motion", det_motion);
    g_unconstr = metric.g_ij;

    ## scale metric from SI coordinates to GCT coordinate conventions
    scale = zeros(size(g_unconstr, 1), 1);
    for i = 1:length(scale)
      switch coordIDs(i)
        case DOPPLERCOORD_GC_NU0
          scale(i) = 2*pi / factorial(1) * (0.5 * T);
        case DOPPLERCOORD_GC_NU1
          scale(i) = 2*pi / factorial(2) * (0.5 * T)^2;
        case DOPPLERCOORD_GC_NU2
          scale(i) = 2*pi / factorial(3) * (0.5 * T)^3;
        case DOPPLERCOORD_GC_NU3
          scale(i) = 2*pi / factorial(4) * (0.5 * T)^4;
        case {DOPPLERCOORD_N3X_EQU, DOPPLERCOORD_N3Y_EQU, DOPPLERCOORD_N3Z_EQU}
          tau_E = LAL_REARTH_SI / LAL_C_SI;
          scale(i) = 2*pi * fiducial_freq * tau_E * cos(detLat);
        otherwise
          error("%s: unexpected coordinate ID '%i'!", funcName, coordIDs(i));
      endswitch
    endfor
    for i = 1:size(g_unconstr, 1)
      for j = 1:size(g_unconstr, 2)
        g_unconstr(i, j) /= scale(i) * scale(j);
      endfor
    endfor

    ## save metric in cache
    gcache.g_unconstr = g_unconstr;
    gcache.coordIDs = coordIDs;

  endif

  ## find indices of unconstrained sky coordinates
  inx = find(gcache.coordIDs == DOPPLERCOORD_N3X_EQU);
  iny = find(gcache.coordIDs == DOPPLERCOORD_N3Y_EQU);
  inz = find(gcache.coordIDs == DOPPLERCOORD_N3Z_EQU);

  ## compute transform from unconstrained to constrained metric,
  ## for each choice of alpha and delta
  alphaD = detLong + zeroLong;
  alpha = reshape(alpha, 1, 1, []);
  delta = reshape(delta, 1, 1, []);
  cos_alpha = cos(alpha - alphaD);
  sin_alpha = sin(alpha - alphaD);
  cot_delta = cot(delta);
  constr_T = zeros([size(gcache.g_unconstr), length(alpha)]);
  for n = 1:size(gcache.g_unconstr, 1)
    constr_T(n, n, :) = 1;
  endfor
  constr_T(inz, inx, :) = -cos_alpha .* cot_delta;
  constr_T(inz, iny, :) = -sin_alpha .* cot_delta;
  constr_T(:, inz, :) = [];

  ## compute constrained metric in GCT coordinates
  g = cat(3, arrayfun(@(n) constr_T(:, :, n)' * gcache.g_unconstr * constr_T(:, :, n), 1:length(alpha), "UniformOutput", false){:});

endfunction

## check GCT implementation against super-sky and Taylor-expanded metrics
%!test
%!
%!  # check that LALSuite wrappings are available
%!  try
%!    lal; lalpulsar;
%!    ephemerides = loadEphemerides();
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!
%!  # common parameters
%!  smax = 2;
%!  t0 = 812345678;
%!  T = 86400;
%!  alpha1 = 1.3;
%!  delta1 = 0.3;
%!  detector = "H1";
%!  fiducial_freq = 100;
%!
%!  # loop over ptolemaic and tj offset
%!  ptole = {false, "spin+orbit"; true, "spin+ptoleorbit"};
%!  for p = 1:size(ptole, 1)
%!    for dt = [-10, 0, 10]*86400
%!      tj = t0 + dt;
%!
%!      # compute super-sky metric in GCT coordinates
%!      metric = CreateDopplerMetric("coords", "freq,fdots,ssky_equ", "spindowns", smax, "segment_list", [tj - 0.5 * T, tj + 0.5 * T], "ref_time", t0, "detectors", detector, "ephemerides", ephemerides, "fiducial_freq", fiducial_freq, "det_motion", ptole{p, 2});
%!      g_ssky = metric.g_ij;
%!
%!      # compute full GCT metric
%!      g_gct = GCTCoherentFullMetric([], "smax", smax, "tj", tj, "t0", t0, "T", T, "alpha", alpha1, "delta", delta1, "detector", detector, "ptolemaic", ptole{p, 1});
%!
%!      # compute Taylor-expanded GCT metric
%!      g_gct_tay = GCTCoherentTaylorMetric("smax", smax, "tj", tj, "t0", t0, "T", T);
%!
%!      # loop over sky/frequency parameter offset sizes
%!      for a = [1, 4, 7, 10]
%!        for b = [1, 4, 7, 10]
%!
%!          # compute sky position and frequency offset
%!          alpha2 = alpha1 + a * 1e-4;
%!          delta2 = delta1 + a * 1e-4;
%!          n1 = [cos(alpha1)*cos(delta1); sin(alpha1)*cos(delta1); sin(delta1)];
%!          n2 = [cos(alpha2)*cos(delta2); sin(alpha2)*cos(delta2); sin(delta2)];
%!          fndot1 = [fiducial_freq; 0; 0];
%!          fndot2 = fndot1 + b * [1e-7; 1e-11; 1e-15];
%!
%!          # compute super-sky metric mismatch
%!          dssky = [fndot2 - fndot1; n2 - n1];
%!          mu_ssky = dot(dssky, g_ssky * dssky);
%!
%!          # compute GCT coordinates
%!          gct1 = GCTCoordinates("t0", t0, "T", T, "alpha", alpha1, "delta", delta1, "fndot", fndot1, "detector", detector, "ephemerides", ephemerides, "ptolemaic", ptole{p, 1});
%!          gct2 = GCTCoordinates("t0", t0, "T", T, "alpha", alpha2, "delta", delta2, "fndot", fndot2, "detector", detector, "ephemerides", ephemerides, "ptolemaic", ptole{p, 1});
%!
%!          # compute full GCT metric mismatch
%!          dgct = gct2 - gct1;
%!          mu_gct = dot(dgct, g_gct * dgct);
%!
%!          # compute Taylor-expanded GCT mismatch
%!          mu_gct_tay = dot(dgct, g_gct_tay * dgct);
%!
%!          # check that differences are relatively small
%!          assert(abs(mu_gct - mu_ssky) < 0.05 * abs(mu_ssky));
%!          assert(abs(mu_gct_tay - mu_ssky) < 0.05 * abs(mu_ssky));
%!
%!        endfor
%!      endfor
%!    endfor
%!  endfor
