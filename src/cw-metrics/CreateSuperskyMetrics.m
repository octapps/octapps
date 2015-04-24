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
##   [rssky_metric, rssky_transf, ussky_metric] = CreateSuperskyMetrics("opt", val, ...)
## where:
##   rssky_metric       = reduced supersky metric, appropriately averaged over segments
##   rssky_transf       = reduced supersky metric transform data
##   ussky_metric       = unconstrained supersky metric, appropriately averaged over segments
## Options:
##   "spindowns"        : number of spindown coordinates: 0=none, 1=1st spindown, 2=1st+2nd spindown, etc.
##   "segment_list"     : list of segments [start_time, end_time; start_time, end_time; ...] in GPS seconds
##   "ref_time"         : reference time in GPS seconds [default: mean of segment list start/end times]
##   "fiducial_freq"    : fiducial frequency for sky-position coordinates [required]
##   "detectors"        : comma-separated list of detector names [required]
##   "detector_weights" : vector of weights used to combine single-detector metrics [default: unit weights]
##   "detector_motion"  : which detector motion to use [default: spin+orbit]
##   "ephemerides"      : Earth/Sun ephemerides [default: load from loadEphemerides()]

function [rssky_metric, rssky_transf, ussky_metric] = CreateSuperskyMetrics(varargin)

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
    [rssky_metric, rssky_transf, ussky_metric] = ...
    XLALComputeSuperskyMetrics(0, 0, 0,  ...
                               spindowns, ref_time, SegmentList, fiducial_freq, ...
                               MultiLALDet, MultiNoise, DetMotion, ephemerides ...
                              );
  catch
    error("%s: Could not compute supersky metrics", funcName);
  end_try_catch

  ## return metrics
  rssky_metric = native(rssky_metric);
  rssky_transf = native(rssky_transf);
  ussky_metric = native(ussky_metric);

endfunction
