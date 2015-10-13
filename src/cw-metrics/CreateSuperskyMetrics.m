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

## Create the supersky parameter-space metrics.
## Usage:
##   metrics = CreateSuperskyMetrics("opt", val, ...)
## where 'metrics' is a struct containing the following fields:
##   coh_rssky_metric   = coherent reduced supersky metric for each segment
##   coh_rssky_transf   = coherent reduced supersky metric coordinate transform data for each segment
##   semi_rssky_metric  = semicoherent reduced supersky metric
##   semi_rssky_transf  = semicoherent reduced supersky metric coordinate transform data
## Options:
##   "spindowns"        : number of spindown coordinates: 0=none, 1=1st spindown, 2=1st+2nd spindown, etc.
##   "segment_list"     : list of segments [start_time, end_time; start_time, end_time; ...] in GPS seconds
##   "ref_time"         : reference time in GPS seconds [default: mean of segment list start/end times]
##   "fiducial_freq"    : fiducial frequency for sky-position coordinates [required]
##   "detectors"        : comma-separated list of detector names [required]
##   "detector_weights" : vector of weights used to combine single-detector metrics [default: unit weights]
##   "detector_motion"  : which detector motion to use [default: spin+orbit]
##   "ephemerides"      : Earth/Sun ephemerides [default: load from loadEphemerides()]

function metrics = CreateSuperskyMetrics(varargin)

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
    SSkyMetrics = XLALComputeSuperskyMetrics( ...
                                              spindowns, ref_time, SegmentList, fiducial_freq, ...
                                              MultiLALDet, MultiNoise, DetMotion, ephemerides ...
                                            );
  catch
    error("%s: Could not compute supersky metrics", funcName);
  end_try_catch

  ## fill metrics struct
  metrics = struct;
  metrics.coh_rssky_metric = cellfun(@native, SSkyMetrics.coh_rssky_metric, "uniformoutput", false);
  metrics.coh_rssky_transf = cellfun(@native, SSkyMetrics.coh_rssky_transf, "uniformoutput", false);
  metrics.semi_rssky_metric = native(SSkyMetrics.semi_rssky_metric);
  metrics.semi_rssky_transf = native(SSkyMetrics.semi_rssky_transf);

endfunction


%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  metrics = CreateSuperskyMetrics( ...
%!                                   "spindowns", 1, ...
%!                                   "segment_list", CreateSegmentList(1e9, 5, 86400, [], 0.75), ...
%!                                   "fiducial_freq", 123.4, ...
%!                                   "detectors", "H1,L1" ...
%!                                 );
