## Copyright (C) 2012 Karl Wette
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

## Create various Doppler phase- and Fstat metrics.
## Usage:
##   [metric, coordIDs] = CreateDopplerMetric("opt", val, ...)
## where:
##   metric   = Doppler metric, with struct-elements (depending on metric_type)
##                metric.g_ij: phase metric
##                metric.gF_ij: full F-stat metric
##                metric.gFav_ij: averaged F-stat metric
##   coordIDs = coordinate IDs of the chosen coordinates
## Options:
##   "coords"          : comma-separated list of coordinates:
##                         "alpha_delta": physical sky coordinates
##                         "ssky_equ": super-sky in equatorial coordinates
##                         "ssky_ecl": super-sky in ecliptic coordinates
##                         "spin_equ": spin sky in x-y equatorial coordinates
##                         "orbit_ecl": orbit sky in x-y-z ecliptic coordinates
##                         "freq": frequency in SI units
##                         "fdots": frequency spindowns in SI units
##                         "gct_nu": GCT frequency/spindowns in SI units
##                         "gct_nx_ny_equ": GCT constrained equatorial sky coordinates
##   "spindowns"       : number of spindown coordinates: 0=none, 1=1st spindown, 2=1st+2nd spindown, etc.
##   "ref_time"        : reference time in GPS seconds [default: mean of segment start/end times]
##   "start_time"      : start time(s) in GPS seconds of each segment [used with end_time or time_span]
##   "mid_time"        : mid time(s) in GPS seconds of each segment [used with time_span]
##   "end_time"        : end time(s) in GPS seconds of each segment [used with start_time or time_span]
##   "time_span"       : time span(s) in seconds of each segment [used with start_time, end_time, or mid_time]
##   "detectors"       : comma-separated list of detector names
##   "ephemerides"     : Earth/Sun ephemerides from loadEphemerides()
##   "fiducial_freq"   : fiducial frequency for sky-position coordinates
##   "det_motion"      : which detector motion to use (default: spin+orbit)
##   "alpha"           : for physical sky coordinates, right ascension to compute metric at
##   "delta"           : for physical sky coordinates, declination to compute metric at
##   "npos_eval"       : if >0, return a metric with no more than this number of non-positive eigenvalues
##   "metric_type"     : compute either phase metric (METRIC_TYPE_PHASE), F-stat metric (METRIC_TYPE_FSTAT)
##                       or both (METRIC_TYPE_ALL)
##   "cosi"            : cos(iota) signal parameter for full F-stat metric (gF_ij)
##   "psi"             : polarization angle signal parameter for full F-stat metric (gF_ij)

function [metric, coordIDs] = CreateDopplerMetric(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"coords", "char"},
               {"spindowns", "integer,positive,scalar"},
               {"ref_time", "real,strictpos,scalar", []},
               {"start_time", "real,strictpos,vector", []},
               {"mid_time", "real,strictpos,vector", []},
               {"end_time", "real,strictpos,vector", []},
               {"time_span", "real,strictpos,vector", []},
               {"detectors", "char"},
               {"ephemerides", "a:swig_ref", []},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"det_motion", "char", "spin+orbit"},
               {"alpha", "real,scalar", 0},
               {"delta", "real,scalar", 0},
               {"npos_eval", "integer,positive,scalar", 0},
               {"metric_type", "integer,scalar", METRIC_TYPE_PHASE},
               {"cosi", "real,scalar", 0},
               {"psi", "real,scalar", 0},
               []);

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## parse segment times
  [ref_time, start_time, end_time] = parseSegmentTimes(ref_time, start_time, mid_time, end_time, time_span,
                                                       ephemerides.ephemE{1}.gps || ephemerides.ephemE{end}.gps);

  ## create metric parameters struct
  par = new_DopplerMetricParams;

  ## create coordinate system
  coordIDs = [];
  coord_list = strsplit(coords, ",");
  for i = 1:length(coord_list)
    switch coord_list{i}
      case "alpha_delta"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_ALPHA, ...
                    DOPPLERCOORD_DELTA];
      case "ssky_equ"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_N3X_EQU, ...
                    DOPPLERCOORD_N3Y_EQU, ...
                    DOPPLERCOORD_N3Z_EQU];
      case "ssky_ecl"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_N3X_ECL, ...
                    DOPPLERCOORD_N3Y_ECL, ...
                    DOPPLERCOORD_N3Z_ECL];
      case "spin_equ"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_N3SX_EQU, ...
                    DOPPLERCOORD_N3SY_EQU];
      case "orbit_ecl"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_N3OX_ECL, ...
                    DOPPLERCOORD_N3OY_ECL, ...
                    DOPPLERCOORD_N3OZ_ECL];
      case "freq"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_FREQ];
      case "fdots"
        spindownCoordIDs = [DOPPLERCOORD_F1DOT, ...
                            DOPPLERCOORD_F2DOT, ...
                            DOPPLERCOORD_F3DOT];
        if spindowns > length(spindownCoordIDs)
          error("%s: maximum of %i spindowns supported", funcName, length(spindownCoordIDs));
        endif
        coordIDs = [coordIDs, ...
                    spindownCoordIDs(1:spindowns)];
      case "gct_nu"
        spindownCoordIDs = [DOPPLERCOORD_GC_NU1, ...
                            DOPPLERCOORD_GC_NU2, ...
                            DOPPLERCOORD_GC_NU3];
        if spindowns > length(spindownCoordIDs)
          error("%s: maximum of %i spindowns supported", funcName, length(spindownCoordIDs));
        endif
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_GC_NU0, ...
                    spindownCoordIDs(1:spindowns)];
      case "gct_nx_ny_equ"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_N2X_EQU, ...
                    DOPPLERCOORD_N2Y_EQU];
      otherwise
        error("%s: unknown coordinates '%s'", funcName, coords)
    endswitch
  endfor
  par.coordSys.coordIDs(1:length(coordIDs)) = coordIDs;
  par.coordSys.dim = length(coordIDs);

  ## set detector information
  detNames = XLALCreateStringVector(strsplit(detectors, ",", true){:});
  XLALParseMultiLALDetector(par.multiIFO, detNames);
  par.multiNoiseFloor.length = 0; ## zero here means unspecified noise-floors, and therefore unit-weights

  ## set detector motion
  try
    par.detMotionType = XLALParseDetectorMotionString(det_motion);
  catch
    error("%s: unknown detector motion '%s'", funcName, det_motion)
  end_try_catch

  ## do not include sky-position-dependent Roemer delay in time variable
  par.approxPhase = true;

  ## set metric type to return
  par.metricType = metric_type;

  ## do not project coordinates
  par.projectCoord = -1;

  ## set F-stat-metric-relevant amplitude signal parameters
  par.signalParams.Amp.cosi = cosi;
  par.signalParams.Amp.psi  = psi;

  ## set fiducial frequency and sky position
  par.signalParams.Doppler.Alpha = alpha;
  par.signalParams.Doppler.Delta = delta;
  par.signalParams.Doppler.fkdot(1) = fiducial_freq;

  ## create LAL segment list
  par.signalParams.Doppler.refTime = ref_time;
  XLALSegListInit(par.segmentList);
  for i = 1:length(start_time)
    seg = new_LALSeg;
    XLALSegSet(seg, start_time(i), end_time(i), i);
    XLALSegListAppend(par.segmentList, seg);
  endfor

  ## set non-positive eigenvalue threshold
  par.nonposEigValThresh = npos_eval;

  ## calculate Doppler metric
  try
    retn = XLALDopplerFstatMetric(par, ephemerides);
  catch
    error("%s: Could not calculate Doppler metric", funcName);
  end_try_catch

  ## return Doppler metric
  if ( (metric_type == METRIC_TYPE_PHASE) || (metric_type == METRIC_TYPE_ALL) )
    metric.g_ij = retn.g_ij.data(:,:);
  else
    metric.g_ij = [];
  endif
  if ( (metric_type == METRIC_TYPE_FSTAT) || (metric_type == METRIC_TYPE_ALL) )
    metric.gF_ij = retn.gF_ij.data(:,:);
    metric.gFav_ij = retn.gFav_ij.data(:,:);
  else
    metric.gF_ij = [];
    metric.gFav_ij = [];
  endif

  ## cleanup
  XLALSegListClear(par.segmentList);

endfunction
