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
##             "ssky_equ": 3-sky in equatorial coordinates
##             "ssky_ecl": 3-sky in ecliptic coordinates
##             "spin_equ": spin 2-sky in x-y equatorial coordinates
##             "orbit_ecl": orbit 3-sky in x-y-z ecliptic coordinates
##             "freq": frequency in SI units
##             "fdots": frequency spindowns in SI units
##   "spindowns": number of frequency spindown coordinates
##   "start_time": start time in GPS seconds (default: ref_time - 0.5*time_span)
##   "ref_time": reference time in GPS seconds (default: start_time + 0.5*time_span)
##   "time_span": observation time-span in seconds
##   "detectors": comma-separated list of detector names
##   "ephem_year": ephemerides year (default: 05-09)
##   "fiducial_freq": fiducial frequency for sky-position coordinates
##   "phase_model": whether to use Phase_model approximation (default: false)

function [metric, coordIDs] = CreatePhaseMetric(varargin)

  ## parse options
  parseOptions(varargin,
               {"coords", "char"},
               {"spindowns", "integer,positive,scalar"},
               {"start_time", "real,strictpos,scalar", []},
               {"ref_time", "real,strictpos,scalar", []},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephem_year", "char", "05-09"},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"phase_model", "char", "full"},
               []);
  if isempty(start_time) && isempty(ref_time)
    error("%s: one of 'start_time' and 'ref_time' must be given", funcName);
  endif

  ## load LAL libraries
  lal;
  lalpulsar;

  ## load ephemerides
  earth_ephem = sprintf("earth%s.dat", ephem_year);
  sun_ephem = sprintf("sun%s.dat", ephem_year);
  try
    ephemerides = InitBarycenter(earth_ephem, sun_ephem);
  catch
    error("%s: Could not load ephemerides", funcName);
  end_try_catch

  ## check start time and reference time
  if isempty(start_time)
    start_time = ref_time - 0.5*time_span;
  elseif isempty(ref_time)
    ref_time = start_time + 0.5*time_span;
  endif
  if start_time < ephemerides.ephemE{1}.gps || ephemerides.ephemE{end}.gps < start_time + time_span
    error("%s: time span [%f,%f] is outside range of ephemerides", funcName, start_time, start_time + time_span);
  endif

  ## create metric parameters struct
  par = new_DopplerMetricParams;

  ## create list of spindown coordinates
  spindownCoordIDs = [DOPPLERCOORD_F1DOT, ...
                      DOPPLERCOORD_F2DOT, ...
                      DOPPLERCOORD_F3DOT];
  if spindowns > length(spindownCoordIDs)
    error("%s: maximum of %i spindowns supported", funcName, length(spindownCoordIDs));
  endif
  spindownCoordIDs = spindownCoordIDs(1:spindowns);

  ## create coordinate system
  coordIDs = [];
  coord_list = strsplit(coords, ",");
  for i = 1:length(coord_list)
    switch coord_list{i}
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
        coordIDs = [coordIDs, ...
                    spindownCoordIDs];
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
  switch phase_model
    case "full"
      par.detMotionType = DETMOTION_SPIN_ORBIT;
    case "ptolemaic"
      par.detMotionType = DETMOTION_SPIN_PTOLEORBIT;
    case "linearI"
      par.detMotionType = DETMOTION_ORBIT_SPINXY;
    case {"linearII", "orbital"}
      par.detMotionType = DETMOTION_ORBIT;
    otherwise
      error("%s: unknown phase model '%s'", funcName, phase_model)
  endswitch

  ## do not include sky-position-dependent Roemer delay in time variable
  par.approxPhase = true;

  ## set metric type to return
  par.metricType = METRIC_TYPE_PHASE;

  ## do not project coordinates
  par.projectCoord = -1;

  ## set fiducial frequency
  par.signalParams.Doppler.fkdot(1) = fiducial_freq;

  ## set start time, reference time, and time span
  GPSSetREAL8(par.signalParams.Doppler.refTime, ref_time);
  SegListInitSimpleSegments(par.segmentList, LIGOTimeGPS(start_time), 1, time_span);

  ## calculate Doppler phase metric
  try
    [metric_retn, metric_err] = DopplerPhaseMetric(par, ephemerides);
  catch
    error("%s: Could not calculate phase metric", funcName);
  end_try_catch
  metric = metric_retn.data(:,:);

endfunction
