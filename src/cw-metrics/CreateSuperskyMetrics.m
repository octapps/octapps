## Copyright (C) 2012, 2014 Karl Wette
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

## Create the supersky and reduced supersky phase metrics.
## Usage:
##   out = CreateSuperskyMetrics("opt", val, ...)
## where 'out' is a struct containing the fields:
##   rssky_metric       = Reduced supersky metric, appropriately averaged over segments
##   rssky_transf       = Reduced supersky metric transform data
##   ssky_metric        = (Full) supersky metric, appropriately averaged over segments
##   rssky_metric_seg   = Reduced supersky metrics for each segment as a cell array
##   rssky_transf_seg   = Reduced supersky metric transform data for each segment as a cell array
##   ssky_metric_seg    = (Full) supersky metrics for each segment as a cell array
## Options:
##   "spindowns"        : number of spindown coordinates: 0=none, 1=1st spindown, 2=1st+2nd spindown, etc.
##   "segment_list"     : list of segments [start_time, end_time; start_time, end_time; ...] in GPS seconds
##   "ref_time"         : reference time in GPS seconds [default: mean of segment list start/end times]
##   "fiducial_freq"    : fiducial frequency for sky-position coordinates [required]
##   "detectors"        : comma-separated list of detector names [required]
##   "detector_weights" : vector of weights used to combine single-detector metrics [default: unit weights]
##   "detector_motion"  : which detector motion to use [default: spin+orbit]
##   "ephemerides"      : Earth/Sun ephemerides [default: load from loadEphemerides()]

function out = CreateSuperskyMetrics(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"spindowns", "integer,positive,scalar"},
               {"segment_list", "real,strictpos,matrix,cols:2"},
               {"ref_time", "real,strictpos,scalar", []},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"detector_weights", "real,strictpos,vector", []},
               {"detector_motion", "char", "spin+orbit"},
               {"ephemerides", "a:swig_ref", []},
               []);

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## create LAL segment list and set reference time
  SegmentList = XLALSegListCreate();
  for i = 1:size(segment_list, 1)
    seg = new_LALSeg;
    XLALSegSet(seg, segment_list(i, 1), segment_list(i, 2), i);
    XLALSegListAppend(SegmentList, seg);
  endfor
  if isempty(ref_time)
    ref_time = mean(segment_list(:));
  endif

  ## set detector information
  DetNames = XLALCreateStringVector(strsplit(detectors, ",", true){:});
  MultiLALDet = new_MultiLALDetector;
  XLALParseMultiLALDetector(MultiLALDet, DetNames);
  MultiNoise = new_MultiNoiseFloor;
  MultiNoise.length = length(detector_weights);
  MultiNoise.sqrtSn(1:length(detector_weights)) = detector_weights;
  try
    DetMotion = XLALParseDetectorMotionString(detector_motion);
  catch
    error("%s: unknown detector motion '%s'", funcName, detector_motion)
  end_try_catch

  ## compute supersky metrics
  try
    [rssky_metric, rssky_transf, ssky_metric, ...
     rssky_metric_seg, rssky_transf_seg, ssky_metric_seg] = ...
    XLALComputeSuperskyMetrics(0, 0, 0, 0, 0, 0, ...
                               spindowns, ref_time, SegmentList, fiducial_freq, ...
                               MultiLALDet, MultiNoise, DetMotion, ephemerides);
  catch
    error("%s: Could not compute supersky metric", funcName);
  end_try_catch

  ## return metrics
  out = struct;
  out.rssky_metric = native(rssky_metric);
  out.rssky_transf = native(rssky_transf);
  out.ssky_metric = native(ssky_metric);
  out.rssky_metric_seg = mat2cell(native(rssky_metric_seg), size(out.rssky_metric, 1), size(out.rssky_metric, 2) * ones(1, size(segment_list, 1)));
  out.rssky_transf_seg = mat2cell(native(rssky_transf_seg), size(out.rssky_transf, 1), size(out.rssky_transf, 2) * ones(1, size(segment_list, 1)));
  out.ssky_metric_seg = mat2cell(native(ssky_metric_seg), size(out.ssky_metric, 1), size(out.ssky_metric, 2) * ones(1, size(segment_list, 1)));

endfunction


##### first implementation of the reduced supersky metric construction in Octave #####
##### now a reference implementation to compare against CreateSuperskyMetric()    #####

%!function out = ConstructSuperskyMetrics(varargin)
%!
%!  ## load LAL libraries
%!  lal;
%!  lalpulsar;
%!
%!  ## parse options
%!  parseOptions(varargin,
%!               {"spindowns", "integer,positive,scalar"},
%!               {"segment_list", "real,strictpos,matrix,cols:2"},
%!               {"ref_time", "real,strictpos,scalar", []},
%!               {"fiducial_freq", "real,strictpos,scalar"},
%!               {"detectors", "char"},
%!               {"detector_weights", "real,strictpos,vector", []},
%!               {"detector_motion", "char", "spin+orbit"},
%!               {"ephemerides", "a:swig_ref", []},
%!               []);
%!
%!  ## load ephemerides if not supplied
%!  if isempty(ephemerides)
%!    ephemerides = loadEphemerides();
%!  endif
%!
%!  ## call CreateDopplerMetric() to create expanded supersky metric
%!  [metric, ess_cIDs] = CreateDopplerMetric("coords", "spin_equ,orbit_ecl,fdots,freq", ...
%!                                           "spindowns", spindowns, ...
%!                                           "segment_list", segment_list, ...
%!                                           "ref_time", ref_time, ...
%!                                           "detectors", detectors, ...
%!                                           "ephemerides", ephemerides, ...
%!                                           "fiducial_freq", fiducial_freq, ...
%!                                           "det_motion", detector_motion, ...
%!                                           "npos_eval", 2);
%!  essky_metric = metric.g_ij;
%!  assert(issymmetric(essky_metric) > 0);
%!  assert(isvector(ess_cIDs));
%!  assert(length(unique(ess_cIDs)) == length(ess_cIDs));
%!
%!  ## diagonal-normalise expanded supersky metric
%!  ## use "tolerant" since orbital Z may be zero, for Ptolemaic ephemerides
%!  [nessky_metric, dessky_metric, idessky_metric] = DiagonalNormaliseMetric(essky_metric, "tolerant");
%!
%!  ## check diagonalised expanded supersky metric does not have more than 1 negative eigenvalue
%!  nessky_metric_num_neg_eval = length(find(eig(nessky_metric) <= 0));
%!  if nessky_metric_num_neg_eval > 1
%!    error("%s: 'nessky_metric' is not sufficiently positive definite (%i negative eigenvalues)", funcName, nessky_metric_num_neg_eval);
%!  endif
%!
%!  ## get coordinates of spin, orbital, frequency and spindown coordinates
%!  insx = find(ess_cIDs == DOPPLERCOORD_N3SX_EQU);
%!  assert(length(insx) > 0);
%!  insy = find(ess_cIDs == DOPPLERCOORD_N3SY_EQU);
%!  assert(length(insy) > 0);
%!  inoX = find(ess_cIDs == DOPPLERCOORD_N3OX_ECL);
%!  assert(length(inoX) > 0);
%!  inoY = find(ess_cIDs == DOPPLERCOORD_N3OY_ECL);
%!  assert(length(inoY) > 0);
%!  inoZ = find(ess_cIDs == DOPPLERCOORD_N3OZ_ECL);
%!  assert(length(inoZ) > 0);
%!  ifs = [find(ess_cIDs == DOPPLERCOORD_FREQ), ...
%!         find(ess_cIDs == DOPPLERCOORD_F1DOT), ...
%!         find(ess_cIDs == DOPPLERCOORD_F2DOT), ...
%!         find(ess_cIDs == DOPPLERCOORD_F3DOT)];
%!  assert(length(ifs) > 0);
%!
%!  ## reconstruct supersky metric from spin and orbital metric, in requested coordinates
%!  ## adjust coordinate IDs and coordinate indices appropriately
%!  inx = insx;
%!  iny = insy;
%!  inz = inoX;
%!  idel = [inoY, inoZ];
%!  ss_cIDs = ess_cIDs;
%!  skyreconstruct = [1, 0, 0;
%!                    0, 1, 0;
%!                    1, 0, 0;
%!                    0, LAL_COSIEARTH, LAL_SINIEARTH;
%!                    0, -LAL_SINIEARTH, LAL_COSIEARTH];
%!  ss_cIDs([inx, iny, inz]) = [DOPPLERCOORD_N3X_EQU,
%!                              DOPPLERCOORD_N3Y_EQU,
%!                              DOPPLERCOORD_N3Z_EQU];
%!  ss_cIDs(idel) = [];
%!  reconstruct = eye(size(essky_metric));
%!  reconstruct([insx, insy, inoX, inoY, inoZ], [inx, iny, inz]) = skyreconstruct;
%!  reconstruct(:, idel) = [];
%!  ss_inn = [inx, iny, inz];
%!  ss_iff = ifs;
%!  ss_iff(ss_iff > inz) -= 2;
%!
%!  ## reconstruct supersky metric
%!  ssky_metric = reconstruct' * essky_metric * reconstruct;
%!
%!  ## ensure metric is exactly symmetric
%!  ssky_metric = 0.5*(ssky_metric' + ssky_metric);
%!
%!  ## find least-squares linear fit to orbital X and Y by frequency and spindowns
%!  ## - use only spindowns such that fitA' * fitA is full rank
%!  fitted = [inoX, inoY];
%!  fity = nessky_metric(:, fitted);
%!  for n = length(ifs):-1:1
%!    fitting = ifs(1:n);
%!    fitA = nessky_metric(:, fitting);
%!    fitAt_fitA = fitA' * fitA;
%!    if rank(fitAt_fitA) == n
%!      break
%!    endif
%!  endfor
%!  fitcoeffs = fitAt_fitA \ (fitA' * fity);
%!
%!  ## subtract linear fit from orbital X and Y, creating residual coordinates
%!  subtractfit = eye(size(essky_metric));
%!  subtractfit(fitting, fitted) = -fitcoeffs;
%!
%!  ## construct residual supersky metric
%!  residual = dessky_metric * subtractfit * idessky_metric * reconstruct;
%!  rssky_metric = residual' * essky_metric * residual;
%!
%!  ## extract sky offset vectors
%!  skyoff = zeros(length(ifs), 3);
%!  skyoff(1:length(fitting), :) -= residual(fitting, ss_inn);
%!
%!  ## extract sky-sky, sky-frequency, and frequency-frequency blocks
%!  rss_ss = rssky_metric(ss_inn, ss_inn);
%!  rss_sf = rssky_metric(ss_inn, ss_iff);
%!  rss_ff = rssky_metric(ss_iff, ss_iff);
%!
%!  ## diagonally normalise frequency-frequency block
%!  [nrss_ff, drss_ff, idrss_ff] = DiagonalNormaliseMetric(rss_ff);
%!
%!  ## calculate additional sky offset and sky metric adjustment to
%!  ## zero the sky-frequency block of the residual supersky metric
%!  decoupleoff = drss_ff * (nrss_ff \ (drss_ff * rss_sf'));
%!  decouple_ss = -rss_sf * decoupleoff;
%!
%!  ## decouple residual supersky metric and sky offset vectors
%!  rssky_metric(ss_inn, ss_inn) += decouple_ss;
%!  rssky_metric(ss_inn, ss_iff) = 0;
%!  rssky_metric(ss_iff, ss_inn) = 0;
%!  skyoff = skyoff + decoupleoff;
%!
%!  ## eigendecompose residual supersky metric sky-sky block
%!  rss_ss = rssky_metric(ss_inn, ss_inn);
%!  [rss_ss_evec, rss_ss_eval] = eig(rss_ss);
%!
%!  ## order eigenvectors in descending order of eigenvalues
%!  [rss_ss_eval, iidescend] = sort(abs(diag(rss_ss_eval)), "descend");
%!  assert(all(rss_ss_eval(1:2) > 0));
%!  rss_ss_eval = diag(rss_ss_eval);
%!  rss_ss_evec = rss_ss_evec(:, iidescend);
%!
%!  ## ensure eigenvalue matrix have positives on diagonal
%!  rss_ss_evec_sign = sign(diag(rss_ss_evec));
%!  rss_ss_evec_sign(rss_ss_evec_sign == 0) = 1;
%!  rss_ss_evec *= diag(rss_ss_evec_sign);
%!
%!  ## ensure eigenvalue matrix has a positive determinant
%!  if det(rss_ss_evec) < 0
%!    rss_ss_evec(:,3) *= -1;
%!  endif
%!
%!  ## align residual supersky metric and sky offset vectors
%!  alignsky = rss_ss_evec';
%!  rssky_metric(ss_inn, ss_inn) = rss_ss_eval;
%!  skyoff = skyoff * alignsky';
%!
%!  ## drop 3rd row/column to get reduced metric
%!  rssky_metric(3, :) = [];
%!  rssky_metric(:, 3) = [];
%!
%!  ## ensure metric is exactly symmetric
%!  rssky_metric = 0.5*(rssky_metric' + rssky_metric);
%!
%!  ## return transform data
%!  rssky_transf = [alignsky; skyoff([2:end, 1], :)];
%!
%!  ## return metrics
%!  out = struct;
%!  out.ssky_metric = ssky_metric;
%!  out.rssky_metric = rssky_metric;
%!  out.rssky_transf = rssky_transf;
%!
%!endfunction

##### compare CreateSuperskyMetrics() against ConstructSuperskyMetrics() #####

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  edat = loadEphemerides();
%!  args = { ...
%!    "spindowns", 1, ...
%!    "segment_list", [800000000, 800200000], ...
%!    "ref_time", 800100000, ...
%!    "fiducial_freq", 123.4, ...
%!    "detectors", "L1", ...
%!    "detector_motion", "spin+orbit", ...
%!    "ephemerides", edat ...
%!  };
%!  out = CreateSuperskyMetrics(args{:});
%!  out0 = ConstructSuperskyMetrics(args{:});
%!  assert(all(abs(out.ssky_metric - out0.ssky_metric) < 1e-8 * max(abs(out0.ssky_metric), 1)));
%!  assert(all(abs(out.rssky_metric - out0.rssky_metric) < 1e-8 * max(abs(out0.rssky_metric), 1)));
%!  assert(all(abs(out.rssky_transf - out0.rssky_transf) < 1e-8 * max(abs(out0.rssky_transf), 1)));

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  edat = loadEphemerides();
%!  args = { ...
%!    "spindowns", 2, ...
%!    "segment_list", [800000000, 801020304], ...
%!    "ref_time", 800000100, ...
%!    "fiducial_freq", 543.2, ...
%!    "detectors", "H1", ...
%!    "detector_motion", "spin+orbit", ...
%!    "ephemerides", edat ...
%!  };
%!  out = CreateSuperskyMetrics(args{:});
%!  out0 = ConstructSuperskyMetrics(args{:});
%!  assert(all(abs(out.ssky_metric - out0.ssky_metric) < 1e-8 * max(abs(out0.ssky_metric), 1)));
%!  assert(all(abs(out.rssky_metric - out0.rssky_metric) < 1e-8 * max(abs(out0.rssky_metric), 1)));
%!  assert(all(abs(out.rssky_transf - out0.rssky_transf) < 1e-6 * max(abs(out0.rssky_transf), 1)));

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  edat = loadEphemerides();
%!  args = { ...
%!    "spindowns", 1, ...
%!    "segment_list", [800000000, 800200000], ...
%!    "ref_time", 800100000, ...
%!    "fiducial_freq", 123.4, ...
%!    "detectors", "L1", ...
%!    "detector_motion", "spin+orbit", ...
%!    "ephemerides", edat ...
%!  };
%!  out = CreateSuperskyMetrics(args{:});
%!  out0 = ConstructSuperskyMetrics(args{:});
%!  assert(all(abs(out.ssky_metric - out0.ssky_metric) < 1e-8 * max(abs(out0.ssky_metric), 1)));
%!  assert(all(abs(out.rssky_metric - out0.rssky_metric) < 1e-8 * max(abs(out0.rssky_metric), 1)));
%!  assert(all(abs(out.rssky_transf - out0.rssky_transf) < 1e-8 * max(abs(out0.rssky_transf), 1)));

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  edat = loadEphemerides();
%!  args = { ...
%!    "spindowns", 2, ...
%!    "segment_list", [800000000, 805000000], ...
%!    "ref_time", 802000000, ...
%!    "fiducial_freq", 543.2, ...
%!    "detectors", "H1", ...
%!    "detector_motion", "spin+orbit", ...
%!    "ephemerides", edat ...
%!  };
%!  out = CreateSuperskyMetrics(args{:});
%!  out0 = ConstructSuperskyMetrics(args{:});
%!  assert(all(abs(out.ssky_metric - out0.ssky_metric) < 1e-8 * max(abs(out0.ssky_metric), 1)));
%!  assert(all(abs(out.rssky_metric - out0.rssky_metric) < 1e-8 * max(abs(out0.rssky_metric), 1)));
%!  assert(all(abs(out.rssky_transf - out0.rssky_transf) < 1e-8 * max(abs(out0.rssky_transf), 1)));
