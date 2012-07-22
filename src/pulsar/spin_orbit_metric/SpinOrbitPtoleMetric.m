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

## Calculate the phase metric w/ Ptolemaic spin/orbital motion
## Usage:
##   M = PtoleApproxMetric(c, T, [f(r)])
## where
##   M = diag-normalised metric(s)
##   c = coordinates:
##       1,2=spin, 3,4=orbit, 5=freq, 6...=spindown
##   T = observation time (seconds)
##   f = (optional) function to display progress as
##       a function of r, the remaining T times
function metrics = PtoleApproxMetric(coords, T)

  ## import LAL libraries
  lal;
  lalpulsar;

  ## spin and orbital periods of Earth in radians/second
  Omega_s = LAL_TWOPI / LAL_DAYSID_SI;
  Omega_o = LAL_TWOPI / LAL_YRSID_SI;

  ## metric dimensions, number of spindowns
  dim = length(coords);

  ## loop over obervation times
  metrics = zeros(dim, dim, length(T));
  for n = 1:length(T)
  
    ## phase components
    phi = cell(dim, 1);
    for i = 1:dim
      switch coords(i)
        case 1   # sky spin 1
          phi{i} = @(t) cos(Omega_s .* t);
        case 2   # sky spin 2
          phi{i} = @(t) sin(Omega_s .* t);
        case 3   # sky orbit 1
          phi{i} = @(t) cos(Omega_o .* t);
        case 4   # sky orbit 2
          phi{i} = @(t) sin(Omega_o .* t);
        otherwise   # frequency order s
          s = coords(i) - 5;
          phi{i} = @(t) (t./T(n)).^(s+1) ./ factorial(s+1);
      endswitch
    endfor

    ## time averages of phase components
    int_phi = zeros(dim, 1);
    for i = 1:dim
      int_phi(i) = TimeAverage(phi{i}, T(n));
    endfor

    ## metric
    metric = zeros(dim, dim);
    for i = 1:dim
      for j = i:dim

        ## time average of product of phase components
        phi_ij = @(t) phi{i}(t) .* phi{j}(t);
        int_phi_ij = TimeAverage(phi_ij, T(n));

        ## metric element
        metric(i,j) = metric(j,i) = int_phi_ij - int_phi(i) * int_phi(j);

      endfor

    endfor

    ## normalised metric
    metric_norm = diag(1 ./ sqrt(diag(metric)));
    metrics(:,:,n) = metric_norm * metric * metric_norm;

  endfor

endfunction

## time average of function
function y = TimeAverage(f, T)
  Ts = linspace(-T/2, T/2, 1 + ceil(T / LAL_DAYSID_SI));
  y = 0;
  for i = 1:length(Ts)-1
    y += quadgk(f, Ts(i), Ts(i+1), "AbsTol", 1e-3);
  endfor
  y /= T;
endfunction
