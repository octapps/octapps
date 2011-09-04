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

## Return parameters of various gravitational wave interferometers
## Syntax:
##   [L, slambda, gamma, zeta] = DetectorLocations(id)
## where:
##   L       = detector's longitude in radians
##   slambda = sine of the detector's latitude
##   gamma   = detector orientation in radians
##   zeta    = angle between interferometer arms in radians
##   id      = identifier of a gravitational wave interferometer

function [L, slambda, gamma, zeta] = DetectorLocations(id)

  ## check input
  assert(ischar(id) && length(id) == 1);
  
  ## select an interferometer
  ## reference:
  ##   B. F. Schutz, "Networks of gravitational wave detectors and three figures of merit", arXiv:1102.5421v2
  switch id
      
    case "H"      # LIGO Hanford
      longitude   = -[119 24 27.6];
      latitude    =  [46 27 18.5];
      orientation = 279;
      
    case "L"      # LIGO Livingston
      longitude   = -[90 46 27.3];
      latitude    =  [30 33 46.4];
      orientation = 208;
      
    case "V"      # VIRGO
      longitude   = [10 30 16];
      latitude    = [43 37 53];
      orientation = 333.5;
      
    otherwise
      error("%s: unknown interferometer identifier '%s'", funcName, id);
      
  endswitch
  
  ## calculate output quantities
  L       =     sum(longitude ./ [180, 180*60, 180*60^2]) * pi;
  slambda = sin(sum(latitude  ./ [180, 180*60, 180*60^2]) * pi);
  gamma = mod(90 - orientation, 360) / 180 * pi;
  zeta = pi/2;

endfunction
