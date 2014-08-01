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

## Create the super-sky reduced super-sky phase metrics.
## Usage:
##   [ssky_metric, rssky_metric, rssky_transf] = CreateSuperSkyMetrics("opt", val, ...)
## where:
##   ssky_metric        = (untransformed) super-sky metric
##   rssky_metric       = reduced super-sky metric
##   rssky_transf       = reduced super-sky metric coordinate transform data
## Options:
##   "spindowns"        : number of spindown coordinates: 0=none, 1=1st spindown, 2=1st+2nd spindown, etc.
##   "ref_time"         : reference time in GPS seconds [required]
##   "segments"         : list of segments [[start1,end1];[start2,end2];...] in GPS seconds [required]
##   "fiducial_freq"    : fiducial frequency for sky-position coordinates [required]
##   "detectors"        : comma-separated list of detector names [required]
##   "detector_weights" : vector of weights used to combine single-detector metrics [default: unit weights]
##   "detector_motion"  : which detector motion to use [default: spin+orbit]
##   "ephemerides"      : Earth/Sun ephemerides [default: load from loadEphemerides()]

function [ssky_metric, rssky_metric, rssky_transf] = CreateSuperSkyMetrics(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"spindowns", "integer,positive,scalar"},
               {"ref_time", "real,strictpos,scalar"},
               {"segments", "real,strictpos,matrix,cols:2"},
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

  ## check segment list
  if !all(segments(:,1) < segments(:,2))
    error("%s: all segment end times (2nd column) must be >= start times (1st column)", funcName);
  endif
  segments = sortrows(segments);
  if segments(1,1) < ephemerides.ephemE{1}.gps || ephemerides.ephemE{end}.gps < segments(end,2)
    error("%s: segment time span [%f,%f] is outside range of ephemerides", funcName, segments(1,1), segments(end,2));
  endif

  ## create SegList from segment list
  SegmentList = new_LALSegList;
  XLALSegListInit(SegmentList);
  for i = 1:size(segments, 1)
    seg = new_LALSeg;
    XLALSegSet(seg, segments(i,1), segments(i,2), i);
    XLALSegListAppend(SegmentList, seg);
  endfor

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

  ## calculate expanded super-sky metric
  try
    ESSkyMetric = XLALExpandedSuperSkyMetric(spindowns, ref_time, SegmentList, fiducial_freq, ...
                                             MultiLALDet, MultiNoise, DetMotion, ephemerides);
  catch
    error("%s: Could not calculate expanded super-sky metric", funcName);
  end_try_catch

  ## calculate super-sky metric
  try
    SSkyMetric = XLALSuperSkyMetric(ESSkyMetric);
    ssky_metric = SSkyMetric.data(:,:);
  catch
    error("%s: Could not calculate super-sky metric", funcName);
  end_try_catch

  ## calculate reduced super-sky metric
  if nargout > 1
    try
      [RSSkyMetric, RSSkyTransform] = XLALReducedSuperSkyMetric(ESSkyMetric);
      rssky_metric = RSSkyMetric.data(:,:);
      rssky_transf = RSSkyTransform.data(:,:);
    catch
      error("%s: Could not calculate reduced super-sky metric", funcName);
    end_try_catch
  endif

  ## cleanup
  XLALSegListClear(SegmentList);

endfunction


##### first implementation of the reduced super-sky metric construction in Octave #####
##### now a reference implementation to compare against CreateSuperSkyMetric()    #####

%!function [ssky_metric, rssky_metric, rssky_transf] = ConstructSuperSkyMetrics(varargin)
%!
%!  ## load LAL libraries
%!  lal;
%!  lalpulsar;
%!
%!  ## parse options
%!  parseOptions(varargin,
%!               {"spindowns", "integer,positive,scalar"},
%!               {"ref_time", "real,strictpos,scalar"},
%!               {"segments", "real,strictpos,matrix,cols:2"},
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
%!  ## call CreateDopplerMetric() to create expanded super-sky metric
%!  [metric, ess_cIDs] = CreateDopplerMetric("coords", "spin_equ,orbit_ecl,fdots,freq", ...
%!                                               "spindowns", spindowns, ...
%!                                               "ref_time", ref_time, ...
%!                                               "start_time", segments(1), ...
%!                                               "time_span", segments(2) - segments(1), ...
%!                                               "detectors", detectors, ...
%!                                               "ephemerides", ephemerides, ...
%!                                               "fiducial_freq", fiducial_freq, ...
%!                                               "det_motion", detector_motion, ...
%!                                               "npos_eval", 2);
%!  essky_metric = metric.g_ij;
%!  assert(issymmetric(essky_metric) > 0);
%!  assert(isvector(ess_cIDs));
%!  assert(length(unique(ess_cIDs)) == length(ess_cIDs));
%!
%!  ## diagonal-normalise expanded super-sky metric
%!  ## use "tolerant" since orbital Z may be zero, for Ptolemaic ephemerides
%!  [nessky_metric, dessky_metric, idessky_metric] = DiagonalNormaliseMetric(essky_metric, "tolerant");
%!
%!  ## check diagonalised expanded super-sky metric does not have more than 1 negative eigenvalue
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
%!  ## reconstruct super-sky metric from spin and orbital metric, in requested coordinates
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
%!  ## reconstruct super-sky metric
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
%!  ## construct residual super-sky metric
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
%!  ## zero the sky-frequency block of the residual super-sky metric
%!  decoupleoff = drss_ff * (nrss_ff \ (drss_ff * rss_sf'));
%!  decouple_ss = -rss_sf * decoupleoff;
%!
%!  ## decouple residual super-sky metric and sky offset vectors
%!  rssky_metric(ss_inn, ss_inn) += decouple_ss;
%!  rssky_metric(ss_inn, ss_iff) = 0;
%!  rssky_metric(ss_iff, ss_inn) = 0;
%!  skyoff = skyoff + decoupleoff;
%!
%!  ## eigendecompose residual super-sky metric sky-sky block
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
%!  ## align residual super-sky metric and sky offset vectors
%!  alignsky = rss_ss_evec';
%!  rssky_metric(ss_inn, ss_inn) = rss_ss_eval;
%!  skyoff = skyoff * alignsky';
%!
%!  ##rssky_metric
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
%!endfunction

##### compare CreateSuperSkyMetrics() against ConstructSuperSkyMetrics() #####

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("*** LALSuite modules not available; skipping test ***"); return;
%!  end_try_catch
%!  edat = loadEphemerides();
%!  args = { ...
%!    "spindowns", 1, ...
%!    "ref_time", 800100000, ...
%!    "segments", [800000000, 800200000], ...
%!    "fiducial_freq", 123.4, ...
%!    "detectors", "L1", ...
%!    "detector_motion", "spin+orbit", ...
%!    "ephemerides", edat ...
%!  };
%!  [ssky, rssky, rsstf] = CreateSuperSkyMetrics(args{:});
%!  [ssky0, rssky0, rsstf0] = ConstructSuperSkyMetrics(args{:});
%!  assert(all(abs(ssky - ssky0) < 1e-8 * max(abs(ssky0), 1)));
%!  assert(all(abs(rssky - rssky0) < 1e-8 * max(abs(rssky0), 1)));
%!  assert(all(abs(rsstf - rsstf0) < 1e-8 * max(abs(rsstf0), 1)));

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("*** LALSuite modules not available; skipping test ***"); return;
%!  end_try_catch
%!  edat = loadEphemerides();
%!  args = { ...
%!    "spindowns", 2, ...
%!    "ref_time", 800000100, ...
%!    "segments", [800000000, 801020304], ...
%!    "fiducial_freq", 543.2, ...
%!    "detectors", "H1", ...
%!    "detector_motion", "spin+orbit", ...
%!    "ephemerides", edat ...
%!  };
%!  [ssky, rssky, rsstf] = CreateSuperSkyMetrics(args{:});
%!  [ssky0, rssky0, rsstf0] = ConstructSuperSkyMetrics(args{:});
%!  assert(all(abs(ssky - ssky0) < 1e-8 * max(abs(ssky0), 1)));
%!  assert(all(abs(rssky - rssky0) < 1e-8 * max(abs(rssky0), 1)));
%!  assert(all(abs(rsstf - rsstf0) < 1e-6 * max(abs(rsstf0), 1)));

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("*** LALSuite modules not available; skipping test ***"); return;
%!  end_try_catch
%!  edat = loadEphemerides();
%!  args = { ...
%!    "spindowns", 2, ...
%!    "ref_time", 840000000, ...
%!    "segments", [900000000, 900200000], ...
%!    "fiducial_freq", 234.5, ...
%!    "detectors", "L1", ...
%!    "detector_motion", "spin+orbit", ...
%!    "ephemerides", edat ...
%!  };
%!  [ssky, rssky, rsstf] = CreateSuperSkyMetrics(args{:});
%!  [ssky0, rssky0, rsstf0] = ConstructSuperSkyMetrics(args{:});
%!  assert(all(abs(ssky - ssky0) < 1e-8 * max(abs(ssky0), 1)));
%!  assert(all(abs(rssky - rssky0) < 1e-6 * max(abs(rssky0), 1)));
%!  assert(all(abs(rsstf - rsstf0) < 1e-6 * max(abs(rsstf0), 1)));
