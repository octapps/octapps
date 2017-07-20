## Copyright (C) 2017 Christoph Dreissigacker
## Copyright (C) 2011 Karl Wette
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

## Return parameters of various gravitational-wave interferometers
## Syntax:
##   [L, slambda, gamma, zeta] = DetectorLocations(detID)
## where:
##   L       = detector's longitude in radians
##   slambda = sine of the detector's latitude
##   gamma   = detector orientation in radians
##   zeta    = angle between interferometer arms in radians
##   detID   = identifier of a gravitational-wave interferometer:
##             "H": LIGO Hanford
##             "L": LIGO Livingston
##             "V": VIRGO
##             "G": GEO
##             "K": KAGRA

function [L, slambda, gamma, zeta] = DetectorLocations(detID)

  ## check input
  assert(ischar(detID) && length(detID) == 1);

  ## select an interferometer
  ## reference:
  ##   lalsuite/lal/src/tools/LALDetectors.h
  switch detID

    case "H"      # LIGO Hanford
      Xarm        = 5.65487724844;
      Yarm        = 4.08408092164;
      longitude   = -2.08405676917;
      latitude    =  0.81079526383;

    case "L"      # LIGO Livingston
      Xarm        = 4.40317772346;
      Yarm        = 2.83238139666;
      longitude   = -1.58430937078;
      latitude    =  0.53342313506;

    case "V"      # VIRGO
      Xarm        = 0.33916285222;
      Yarm        = 5.05155183261;
      longitude   = 0.18333805213;
      latitude    = 0.76151183984;

    case "G"      # GEO
      Xarm        = 1.19360100484;
      Yarm        = 5.83039279401;
      longitude   = 0.17116780435;
      latitude    = 0.91184982752;

    case "K"      # KAGRA
      Xarm        = 1.054113;
      Yarm        = -0.5166798;
      longitude   = 2.396441015;
      latitude    = 0.6355068497;

    otherwise
      error("%s: unknown interferometer identifier '%s'", funcName, detID);

  endswitch
  zeta        = mod(Xarm - Yarm,2*pi);
  orientation = mod(zeta/2 + Yarm,2*pi);

  ## calculate output quantities
  L       =     longitude;
  slambda = sin(latitude  );
  gamma = mod(pi/2 - orientation, 2*pi);

endfunction
