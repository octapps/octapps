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

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{metric}, @var{coordIDs} ] =} ComputeDopplerMetric ( @var{opt}, @var{val}, @dots{} )
##
## Create various Doppler phase- and Fstat metrics.
##
## @heading Arguments
##
## @table @var
## @item metric
## Doppler metric, with struct-elements (depending on metric_type):
##
## @table @var
## @item metric.g_ij
## phase metric
##
## @item metric.gF_ij
## full F-stat metric
##
## @item metric.gFav_ij
## averaged F-stat metric
##
## @end table
##
## @item coordIDs
## coordinate IDs of the chosen coordinates
##
## @end table
##
## @heading Options
##
## @table @code
## @item coords
## comma-separated list of coordinates:
##
## @table @code
## @item alpha_delta
## physical sky coordinates
##
## @item ssky_equ
## super-sky in equatorial coordinates
##
## @item ssky_ecl
## super-sky in ecliptic coordinates
##
## @item spin_equ
## spin sky in x-y equatorial coordinates
##
## @item orbit_ecl
## orbit sky in x-y-z ecliptic coordinates
##
## @item freq
## frequency in SI units
##
## @item fdots
## frequency spindowns in SI units
##
## @item gct_nu
## GCT frequency/spindowns in SI units
##
## @item gct_nx_ny_equ
## GCT constrained equatorial sky coordinates
##
## @end table
##
## @item spindowns
## number of spindown coordinates: 0=none, 1=1st spindown, 2=1st+2nd spindown, etc.
##
## @item segment_list
## list of segments [start_time, end_time; start_time, end_time; @dots{}] in GPS seconds
##
## @item ref_time
## reference time in GPS seconds [default: mean of segment list start/end times]
##
## @item detectors
## comma-separated list of detector names
##
## @item ephemerides
## Earth/Sun ephemerides from @command{loadEphemerides()}
##
## @item fiducial_freq
## fiducial frequency for sky-position coordinates
##
## @item det_motion
## which detector motion to use (default: spin+orbit)
##
## @item alpha
## for physical sky coordinates, right ascension to compute metric at
##
## @item delta
## for physical sky coordinates, declination to compute metric at
##
## @item metric_type
## compute either phase metric (@code{phase}), F-stat metric (@var{Fstat}), or both (@var{all})
##
## @item cosi
## cos(iota) signal parameter for full F-stat metric (gF_ij)
##
## @item psi
## polarization angle signal parameter for full F-stat metric (gF_ij)
##
## @end table
##
## @end deftypefn

function [metric, coordIDs] = ComputeDopplerMetric(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"coords", "char"},
               {"spindowns", "integer,positive,scalar"},
               {"segment_list", "real,strictpos,matrix,cols:2"},
               {"ref_time", "real,strictpos,scalar", []},
               {"detectors", "char"},
               {"ephemerides", "a:swig_ref", []},
               {"fiducial_freq", "real,strictpos,scalar"},
               {"det_motion", "char", "spin+orbit"},
               {"alpha", "real,scalar", 0},
               {"delta", "real,scalar", 0},
               {"metric_type", "char", "phase"},
               {"cosi", "real,scalar", 0},
               {"psi", "real,scalar", 0},
               []);
  assert(strcmp(metric_type, "phase") || strcmp(metric_type, "Fstat") || strcmp(metric_type, "all"));

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
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

  ## do not project coordinates
  par.projectCoord = -1;

  ## set F-stat-metric-relevant amplitude signal parameters
  par.signalParams.Amp.cosi = cosi;
  par.signalParams.Amp.psi  = psi;

  ## set fiducial frequency and sky position
  par.signalParams.Doppler.Alpha = alpha;
  par.signalParams.Doppler.Delta = delta;
  par.signalParams.Doppler.fkdot(1) = fiducial_freq;

  ## create LAL segment list and set reference time
  XLALSegListInit(par.segmentList);
  for i = 1:size(segment_list, 1)
    seg = new_LALSeg;
    XLALSegSet(seg, segment_list(i, 1), segment_list(i, 2), i);
    XLALSegListAppend(par.segmentList, seg);
  endfor
  if isempty(ref_time)
    ref_time = mean(segment_list(:));
  endif
  par.signalParams.Doppler.refTime = ref_time;

  ## calculate Doppler phase metric
  if strcmp(metric_type, "phase") || strcmp(metric_type, "all")
    try
      retn = XLALComputeDopplerPhaseMetric(par, ephemerides);
    catch
      error("%s: Could not calculate Doppler phase metric", funcName);
    end_try_catch
    metric.g_ij = native(retn.g_ij);
  else
    metric.g_ij = [];
  endif

  ## calculate Doppler Fstat metric
  if strcmp(metric_type, "Fstat") || strcmp(metric_type, "all")
    try
      retn = XLALComputeDopplerFstatMetric(par, ephemerides);
    catch
      error("%s: Could not calculate Doppler Fstat metric", funcName);
    end_try_catch
    metric.gF_ij = native(retn.gF_ij);
    metric.gFav_ij = native(retn.gFav_ij);
  else
    metric.gF_ij = [];
    metric.gFav_ij = [];
  endif

  ## cleanup
  XLALSegListClear(par.segmentList);

endfunction

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  out = ComputeDopplerMetric(...
%!    "coords", "spin_equ,orbit_ecl,fdots,freq", ...
%!    "spindowns", 1, ...
%!    "segment_list", [800000000, 800200000], ...
%!    "ref_time", 800100000, ...
%!    "fiducial_freq", 123.4, ...
%!    "detectors", "L1", ...
%!    "det_motion", "spin+orbit" ...
%!  );
%!  assert(isfield(out, "g_ij"));
