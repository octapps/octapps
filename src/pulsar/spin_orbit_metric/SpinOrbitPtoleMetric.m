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

## Calculate the spin-orbit phase metric with Ptolemaic detector motion
## Usage:
##   g_so = SpinOrbitPtoleMetric(coordIDs, tref, Tspan)
## where
##   g_so     = spin-orbit metric (diag-normalised)
##   coordIDs = DOPPLERCOORD_ coordinate IDs
##   site     = detector info (LALDetector)
##   tref     = reference time (LIGOTimeGPS)
##   Tspan    = observation time (seconds)
function g_so = SpinOrbitPtoleMetric(coordIDs, site, tref, Tspan)

  ## check input
  assert(isvector(coordIDs));
  assert(isscalar(Tspan));

  ## import LAL libraries
  lal;
  lalpulsar;

  ## spin and orbital periods of Earth in radians/second
  Omega_s = LAL_TWOPI / LAL_DAYSID_SI;
  Omega_o = LAL_TWOPI / LAL_YRSID_SI;

  ## initial phase of spin motion
  [tMidnight, tAutumn] = GetEarthTimes(tref);
  phi_s = -2*pi * tMidnight / LAL_DAYSID_SI;
  phi_s += site.frDetector.vertexLongitudeRadians;

  ## metric dimensions, number of spindowns
  dim = length(coordIDs);

  ## phase components
  phi = cell(dim, 1);
  for i = 1:dim
    s = [];
    switch coordIDs(i)
      case DOPPLERCOORD_KX
        phi{i} = @(t) cos(phi_s + Omega_s .* t);
      case DOPPLERCOORD_KY
        phi{i} = @(t) sin(phi_s + Omega_s .* t);
      case DOPPLERCOORD_MX
        phi{i} = @(t) cos(Omega_o .* t);
      case DOPPLERCOORD_MY
        phi{i} = @(t) sin(Omega_o .* t);
      case DOPPLERCOORD_W0
        s = 0;
      case DOPPLERCOORD_W1
        s = 1;
      case DOPPLERCOORD_W2
        s = 2;
      case DOPPLERCOORD_W3
        s = 3;
      otherwise
        error("%s: unknown coordID=%i", funcName, coordIDs(i));
    endswitch
    if !isempty(s)
      phi{i} = @(t) (t./Tspan).^(s+1) ./ factorial(s+1);
    endif
  endfor
  
  ## time averages of phase components
  int_phi = zeros(dim, 1);
  for i = 1:dim
    int_phi(i) = TimeAverage(phi{i}, Tspan, LAL_DAYSID_SI);
  endfor

  ## metric
  g = zeros(dim, dim);
  for i = 1:dim
    for j = i:dim
      
      ## time average of product of phase components
      phi_ij = @(t) phi{i}(t) .* phi{j}(t);
      int_phi_ij = TimeAverage(phi_ij, Tspan, LAL_DAYSID_SI);
      
      ## metric element
      g(i,j) = g(j,i) = int_phi_ij - int_phi(i) * int_phi(j);
      
    endfor
    
  endfor

  ## normalised metric
  g_norm = diag(1 ./ sqrt(diag(g)));
  g_so = g_norm * g * g_norm;

endfunction

## time average of function: split averaging
## over given period for improved accuracy
function y = TimeAverage(f, Tspan, P)
  Ts = linspace(-Tspan/2, Tspan/2, 1 + ceil(Tspan / P));
  y = 0;
  for i = 1:length(Ts)-1
    y += quadgk(f, Ts(i), Ts(i+1), "AbsTol", 1e-3);
  endfor
  y /= Tspan;
endfunction
