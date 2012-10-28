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
##             "ssky_equ": super-sky equatorial coordinates
##             "ssky_ecl": super-sky ecliptic coordinates
##             "spin_equ": spin x-y equatorial coordinates
##             "orbit_ecl": orbit x-y ecliptic coordinates
##             "freq": frequency, SI units
##             "fdots": frequency spindowns, SI units
##   "spindowns": number of frequency spindown coordinates
##   "ref_time": reference time in GPS seconds
##   "mid_offset": observation mid-point, in seconds offset from ref_time (default: 0.0)
##   "time_span": observation time-span in seconds
##   "detectors": comma-separated list of detector names
##   "ephem_year": ephemerides year (default: 05-09)
##   "fiducial_freq": fiducial frequency for sky-position coordinates
##   "ptolemaic": whether to use Ptolemaic approximation (default: false)

function [metric, coordIDs] = CreatePhaseMetric(varargin)

  ## parse options
  parseOptions(varargin,
               {"coords", "char"},
               {"spindowns", "integer,positive,scalar"},
               {"ref_time", "real,strictpos,scalar"},
               {"mid_offset", "real,scalar", 0.0},
               {"time_span", "real,strictpos,scalar"},
               {"detectors", "char"},
               {"ephem_year", "char", "05-09"},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"ptolemaic", "logical,scalar", false},
               []);

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

  ## check reference time
  if ref_time < ephemerides.ephemE{1}.gps || ephemerides.ephemE{end}.gps < ref_time
    error("%s: reference time is outside range of ephemerides", funcName);
  endif
  refTime = LIGOTimeGPS(ref_time);

  ## create metric parameters struct
  par = new_DopplerMetricParams;

  ## create list of spindown coordinates
  spindownCoordIDs = [DOPPLERCOORD_F1DOT_SI, ...
                      DOPPLERCOORD_F2DOT_SI, ...
                      DOPPLERCOORD_F3DOT_SI];
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
                    DOPPLERCOORD_NX_EQU, ...
                    DOPPLERCOORD_NY_EQU, ...
                    DOPPLERCOORD_NZ_EQU];
      case "ssky_ecl"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_NX_ECL, ...
                    DOPPLERCOORD_NY_ECL, ...
                    DOPPLERCOORD_NZ_ECL];
      case "spin_equ"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_NSX_EQU, ...
                    DOPPLERCOORD_NSY_EQU];
      case "orbit_ecl"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_NOX_ECL, ...
                    DOPPLERCOORD_NOY_ECL];
      case "freq"
        coordIDs = [coordIDs, ...
                    DOPPLERCOORD_FREQ_SI];
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
  if ptolemaic
    par.detMotionType = DETMOTION_SPIN_PTOLEORBIT;
  else
    par.detMotionType = DETMOTION_SPIN_ORBIT;
  endif

  ## do not include sky-position-dependent Roemer delay in time variable
  par.approxPhase = true;

  ## set metric type to return
  par.metricType = METRIC_TYPE_PHASE;

  ## do not project coordinates
  par.projectCoord = -1;

  ## set fiducial frequency
  par.signalParams.Doppler.fkdot(1) = fiducial_freq;

  ## set reference time, start time, and time span
  par.signalParams.Doppler.refTime = refTime;
  par.startTime = refTime + mid_offset - 0.5 * time_span;
  par.Tspan = time_span;

  ## calculate Doppler phase metric
  try
    [metric_retn, metric_err] = DopplerPhaseMetric(par, ephemerides);
  catch
    error("%s: Could not calculate phase metric", funcName);
  end_try_catch
  metric = metric_retn.data(:,:);

endfunction
