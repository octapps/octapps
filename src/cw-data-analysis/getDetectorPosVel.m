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
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{p}, @var{v}, @var{sp}, @var{sv}, @var{op}, @var{ov} ] =} getDetectorPosVel ( @var{opt}, @var{val}, @dots{} )
##
## Compute the spin, orbital, and total components of a detector's
## position and velocity at a list of GPS times, using LALPulsar
##
## @heading Arguments
##
## @table @var
## @item p
## detector positions, in equatorial coordinates
##
## @item v
## detector velocities, in equatorial coordinates
##
## @item sp
## spin components of detector positions
##
## @item sv
## spin components of detector velocities
##
## @item op
## orbital components of detector positions
##
## @item ov
## orbital components of detector velocities
##
## @end table
##
## @heading Options
##
## @table @code
## @item gps_times
## list of GPS times
##
## @item detector
## name of detector (default: H1)
##
## @item motion
## type of motion (default: spin+orbit)
##
## @item ephemerides
## Earth/Sun ephemerides from @command{loadEphemerides()}
##
## @end table
##
## @end deftypefn

function [p, v, sp, sv, op, ov] = getDetectorPosVel(varargin)

  ## load LAL libraries
  lal;
  lalpulsar;

  ## parse options
  parseOptions(varargin,
               {"gps_times", "real,strictpos,vector"},
               {"detector", "char", "H1"},
               {"motion", "char", "spin+orbit"},
               {"ephemerides", "a:swig_ref", []},
               []);

  ## load ephemerides if not supplied
  if isempty(ephemerides)
    ephemerides = loadEphemerides();
  endif

  ## parse detector string
  multiIFO = new_MultiLALDetector();
  detNames = XLALCreateStringVector(detector);
  XLALParseMultiLALDetector(multiIFO, detNames);
  if multiIFO.length != 1
    error("%s: can only return positions and velocities for a single detector", funcName);
  endif

  ## parse detector motion string
  detMotion = XLALParseDetectorMotionString(motion);

  ## allocate arrays for holding spin and orbital positions and velocities
  sp = sv = op = ov = zeros(3, length(gps_times));

  ## iterate over GPS times
  spv = new_PosVel3D_t();
  opv = new_PosVel3D_t();
  for i = 1:length(gps_times)

    ## get detector spin and orbital position and velocity at given GPS time
    XLALDetectorPosVel(spv, opv, LIGOTimeGPS(gps_times(i)), multiIFO.sites{1}, ephemerides, detMotion);

    ## store spin position and velocity, converting to physical units
    sp(:, i) = spv.pos * LAL_C_SI;
    sv(:, i) = spv.vel * LAL_C_SI;

    ## store orbital position and velocity, converting to physical units
    op(:, i) = opv.pos * LAL_C_SI;
    ov(:, i) = opv.vel * LAL_C_SI;

  endfor

  ## calculate total detector position and velocity
  p = sp + op;
  v = sv + ov;

endfunction

%!test
%!  try
%!    lal; lalpulsar;
%!  catch
%!    disp("skipping test: LALSuite bindings not available"); return;
%!  end_try_catch
%!  [p, v, sp, sv, op, ov] = getDetectorPosVel("gps_times", 800000000 + 100*(0:5));
%!  assert(p, sp + op, 1e-3);
%!  assert(v, sv + ov, 1e-3);
