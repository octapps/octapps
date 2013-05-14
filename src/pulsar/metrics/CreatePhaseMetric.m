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

## Create various flat Doppler phase metrics.
## Usage:
##   [metric, coordIDs] = CreatePhaseMetric(...)
## where:
##   metric   = Doppler metric
##   coordIDs = coordinate IDs of the chosen coordinates
## Options:
##   "coords": comma-separated list of coordinates:
##             "alpha_delta": physical sky coordinates
##             "ssky_equ": super-sky in equatorial coordinates
##             "ssky_ecl": super-sky in ecliptic coordinates
##             "spin_equ": spin sky in x-y equatorial coordinates
##             "orbit_ecl": orbit sky in x-y-z ecliptic coordinates
##             "freq": frequency in SI units
##             "fdots": frequency spindowns in SI units
##             "gct_nu": GCT frequency/spindowns in SI units
##             "gct_nx_ny_equ": GCT constrained equatorial sky coordinates
##   "spindowns": number of frequency spindown coordinates
##   "start_time": start time(s) in GPS seconds (default: [ref_time - 0.5*time_span])
##   "ref_time": reference time in GPS seconds (default: mean(start_time + 0.5*time_span))
##   "time_span": observation time-span in seconds
##   "detectors": comma-separated list of detector names
##   "ephemerides": Earth/Sun ephemerides from loadEphemerides()
##   "fiducial_freq": fiducial frequency for sky-position coordinates
##   "det_motion": which detector motion to use (default: spin+orbit)
##   "alpha": for physical sky coordinates, right ascension to compute metric at
##   "delta": for physical sky coordinates, declination to compute metric at

function [metric, coordIDs, start_time, ref_time] = CreatePhaseMetric(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"coords", "char"},
               {"spindowns", "integer,positive,scalar"},
               {"start_time", "real,strictpos,vector", []},
               {"ref_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephemerides", "a:swig_ref", []},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"det_motion", "char", "spin+orbit"},
               {"alpha", "real,scalar", 0},
               {"delta", "real,scalar", 0},
               []);

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## check start time(s) and reference time
  if isempty(start_time) && isempty(ref_time)
    error("%s: one of 'start_time' and 'ref_time' must be given", funcName);
  endif
  if isempty(start_time)
    start_time = [ref_time - 0.5*time_span];
  elseif isempty(ref_time)
    ref_time = mean(start_time + 0.5*time_span);
  endif
  start_time = sort(start_time);
  if start_time(1) < ephemerides.ephemE{1}.gps || ephemerides.ephemE{end}.gps < start_time(end) + time_span
    error("%s: time span [%f,%f] is outside range of ephemerides", funcName, start_time(1), start_time(end) + time_span);
  endif

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
  detNames = CreateStringVector(strsplit(detectors, ",", true){:});
  ParseMultiDetectorInfo(par.detInfo, detNames, []);

  ## set detector motion
  try
    par.detMotionType = ParseDetectorMotionString(det_motion);
  catch
    error("%s: unknown detector motion '%s'", funcName, det_motion)
  end_try_catch

  ## do not include sky-position-dependent Roemer delay in time variable
  par.approxPhase = true;

  ## set metric type to return
  par.metricType = METRIC_TYPE_PHASE;

  ## do not project coordinates
  par.projectCoord = -1;

  ## set fiducial frequency and sky position
  par.signalParams.Doppler.Alpha = alpha;
  par.signalParams.Doppler.Delta = delta;
  par.signalParams.Doppler.fkdot(1) = fiducial_freq;

  ## set start time, reference time, and time span
  par.signalParams.Doppler.refTime = ref_time;
  SegListInit(par.segmentList);
  for i = 1:length(start_time)
    seg = new_Seg;
    segstart = new_LIGOTimeGPS(start_time(i));
    segend = new_LIGOTimeGPS(start_time(i) + time_span);
    SegSet(seg, segstart, segend, i);
    SegListAppend(par.segmentList, seg);
  endfor

  ## calculate Doppler phase metric
  try
    retn = DopplerFstatMetric(par, ephemerides);
  catch
    error("%s: Could not calculate phase metric", funcName);
  end_try_catch
  metric = retn.g_ij.data(:,:);

  ## cleanup
  SegListClear(par.segmentList);

endfunction
