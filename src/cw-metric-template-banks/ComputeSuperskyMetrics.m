## Copyright (C) 2012, 2014, 2017 Karl Wette
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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{metrics} =} ComputeSuperskyMetrics ( @var{opt}, @var{val}, @dots{} )
##
## Create the supersky parameter-space metrics.
##
## @heading Arguments
## @table @var
## @item metrics
## a struct containing the following fields:
##
## @table @code
## @item coh_rssky_metric
## coherent reduced supersky metric for each segment
##
## @item coh_rssky_transf
## coherent reduced supersky metric coordinate transform data for each segment
##
## @item semi_rssky_metric
## semicoherent reduced supersky metric
##
## @item semi_rssky_transf
## semicoherent reduced supersky metric coordinate transform data
##
## @end table
##
## @end table
##
## @heading Options
##
## @table @code
## @item spindowns
## number of spindown coordinates: 0=none, 1=1st spindown, 2=1st+2nd spindown, etc.
##
## @item segment_list
## list of segments [start_time, end_time; start_time, end_time; ...] in GPS seconds
##
## @item ref_time
## reference time in GPS seconds [default: mean of segment list start/end times]
##
## @item fiducial_freq
## fiducial frequency for sky-position coordinates [required]
##
## @item detectors
## comma-separated list of detector names [required]
##
## @item detector_weights
## vector of weights used to combine single-detector metrics [default: unit weights]
##
## @item detector_motion
## which detector motion to use [default: spin+orbit]
##
## @item ephemerides
## Earth/Sun ephemerides [default: load from @command{loadEphemerides()}]
##
## @item use_cache
## use cache of previously-computed metrics [default: true]
##
## @end table
##
## @end deftypefn

function metrics = ComputeSuperskyMetrics(varargin)

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
               {"use_cache", "logical,scalar", true},
               []);

  ## disable cache for older versions of LAL libraries
  if !exist("XLALCopySuperskyMetrics", "file")
    use_cache = false;
    warning("%s: Supersky metric cache disabled for older installed version of LAL libraries", funcName);
  endif

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## set default reference time
  if isempty(ref_time)
    ref_time = mean(segment_list(:));
  endif

  ## set supersky metrics struct
  metrics = [];

  if use_cache

    ## set in-memory cache of supersky metrics structs
    global supersky_metrics_cache;
    if isempty(supersky_metrics_cache)
      supersky_metrics_cache = struct;
    endif

    ## get cache directory
    cache_dir = SuperskyMetricsCache();

    ## build cache file name
    if isempty(detector_weights)
      detector_weights_str = "def";
    else
      detector_weights_str = sprintf(",%0.4f", detector_weights)(2:end);
    endif
    segment_list_props = AnalyseSegmentList(segment_list);
    cache_file = {
                  sprintf("S%i_R%0.9f_D%s_DW%s_DM%s",
                          spindowns, ref_time, detectors,
                          detector_weights_str, detector_motion),
                  sprintf("N%i_TC%i_TS%i_SL%s.fits",
                          segment_list_props.num_segments,
                          round(segment_list_props.coh_mean_Tspan),
                          round(segment_list_props.inc_Tspan),
                          md5sum(sprintf("-%0.9f", segment_list(:)), true))
    };
    cache_file_short = fullfile(cache_file{end-1:end});
    cache_file = fullfile(mkpath(cache_dir, cache_file{1:end-1}), cache_file{end});

    ## set cache key
    cache_key = sprintf("key_%s", cache_file);

    ## check for supersky metrics in cache
    DebugPrintf(2, "%s: checking for cached metric %s ...\n", funcName, cache_file_short);
    if isfield(supersky_metrics_cache, cache_key)

      ## retrieve from in-memory cache
      metrics = getfield(supersky_metrics_cache, cache_key);
      DebugPrintf(2, "%s:    found in memory\n", funcName);

    elseif exist(cache_file, "file")

      ## read from cache file
      try
        fits_file = XLALFITSFileOpenRead(cache_file);
        metrics = XLALFITSReadSuperskyMetrics(fits_file);
        clear fits_file;
        DebugPrintf(2, "%s:    found on disk\n", funcName);
      catch
        DebugPrintf(2, "%s:    found on disk, but could not load\n", funcName);
      end_try_catch

      ## add to in-memory cache
      supersky_metrics_cache = setfield(supersky_metrics_cache, cache_key, metrics);

    endif

  endif

  ## compute supersky metrics if not in cache
  if isempty(metrics)
    if use_cache
      DebugPrintf(2, "%s:    not found, computing metrics ...", funcName);
    else
      DebugPrintf(2, "%s: computing metrics ...", funcName);
    endif

    ## create LAL segment list
    SegmentList = XLALSegListCreate();
    for i = 1:size(segment_list, 1)
      seg = new_LALSeg;
      XLALSegSet(seg, segment_list(i, 1), segment_list(i, 2), i);
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

    ## compute supersky metrics
    if exist("SUPERSKY_METRIC_TYPE", "var")
      XLALComputeSuperskyMetrics_args = { ...
                                          SUPERSKY_METRIC_TYPE, ...
                                          spindowns, ref_time, SegmentList, fiducial_freq, ...
                                          MultiLALDet, MultiNoise, DetMotion, ephemerides ...
                                        };
    else
      XLALComputeSuperskyMetrics_args = { ...
                                          spindowns, ref_time, SegmentList, fiducial_freq, ...
                                          MultiLALDet, MultiNoise, DetMotion, ephemerides ...
                                        };
    endif
    try
      metrics = XLALComputeSuperskyMetrics(XLALComputeSuperskyMetrics_args{:});
    catch
      if use_cache
        DebugPrintf(2, "\n");
      endif
      error("%s: Could no compute supersky metrics", funcName);
    end_try_catch
    DebugPrintf(2, " done");

    if use_cache

      ## save to cache file
      try
        fits_file = XLALFITSFileOpenWrite(cache_file);
        XLALFITSWriteSuperskyMetrics(fits_file, metrics);
        clear fits_file;
        DebugPrintf(2, "... saved to disk");
      catch
        DebugPrintf(2, "\n");
        error("%s: Could not save supersky metrics to disk", funcName);
      end_try_catch

      ## add to in-memory cache
      supersky_metrics_cache = setfield(supersky_metrics_cache, cache_key, metrics);

    endif

    DebugPrintf(2, "\n");
  endif

  ## make copy of metrics from cache to allow safe modification
  if use_cache
    metrics = XLALCopySuperskyMetrics(metrics);
  endif

  ## ensure fiducial frequency of metrics is as requested
  XLALScaleSuperskyMetricsFiducialFreq(metrics, fiducial_freq);

endfunction

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  metrics = ComputeSuperskyMetrics( ...
%!                                   "spindowns", 1, ...
%!                                   "segment_list", CreateSegmentList(1e9, 5, 86400, [], 0.75), ...
%!                                   "fiducial_freq", 123.4, ...
%!                                   "detectors", "H1,L1", ...
%!                                   "use_cache", false ...
%!                                 );
%!  metrics = ComputeSuperskyMetrics( ...
%!                                   "spindowns", 1, ...
%!                                   "segment_list", CreateSegmentList(1e9, 5, 86400, [], 0.75), ...
%!                                   "fiducial_freq", 123.4, ...
%!                                   "detectors", "H1,L1", ...
%!                                   "use_cache", true ...
%!                                 );
