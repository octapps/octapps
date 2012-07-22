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

## Create pairs of super-sky coordinates s1,s2 = (nx,ny,nz,f,fd,...)
## which are isotropically distributed (given the restriction |n|=1),
## and such that the mismatch between them is equal to mu.
## Usage:
##   [s1, s2] = RandomSuperskyMismatch(mu, g_ss, f1)
## where
##   s1, s2 = super-sky coordinates (in columns)
##   mu     = mismatches (row vector)
##   g_ss   = super-sky metric
##   f1     = initial frequency point
function [s1, s2] = RandomSuperskyMismatch(mu, g_ss, f1)

  ## Check input.
  assert(isscalar(mu));
  assert(mu > 0);
  assert(size(g_ss, 1) == size(g_ss, 2));
  assert(isvector(f1));
  assert(length(f1) == size(g_ss, 1) - 3);

  ## Split super-sky metric into sky-only, frequency-only, and cross metrics.
  g_nn = g_ss(1:3, 1:3);
  g_nf = g_ss(1:3, 4:end);
  g_ff = g_ss(4:end, 4:end);

  ## Choose random mismatches for the sky; once sky positions are generated,
  ## frequency offsets are generated such that the total mismatch is mu.
  mu_nn = rand * mu;

  ## Generate a random rotation matrix using Rodrigues' formula:
  ## a random rotation of th about a random unit vector k.
  k = randn(3, 1);
  k ./= norm(k);
  kx = [0, -k(3), k(2); k(3), 0, -k(1); -k(2), k(1), 0];
  th = rand * 2*pi;
  R = eye(3) + kx * sin(th) + kx * kx * (1 - cos(th));

  ## Choose first sky position unit vector to be the z
  ## direction in the randomly-rotated coordinate frame,
  ## i.e. R*[0;0;1] = R(:,3)
  n1 = R(:,3);

  ## Rotate sky metric into the randomly-rotated coordinates
  g_nn_z = R' * g_nn * R;

  ## Eigen-decompose the metric of the 2D ellipse in the x-y
  ## plane, perpendicular to n1, i.e. in the plane tangent to
  ## n1 in physical coordinates, which is approximately the
  ## intersection of the super-sky metric with the sky sphere.
  [V_nn_z, D_nn_z] = eig(g_nn_z(1:2, 1:2));

  ## Try to find second sky position unit vector
  do

    ## Choose a random 2D offset in the tangent plane, scaled
    ## to be isotropically distributed on the edge of the 2D
    ## metric ellipse in the tangent plane, and with a mismatch
    ## of mu_nn.
    dn = inv(sqrt(D_nn_z)) * randn(2,1);
    dn .*= sqrt(mu_nn / dot(dn, D_nn_z * dn));
    dn = V_nn_z * dn;

    ## Rotate offset back to physical, 3D coordinates.
    dn = R * [dn; 0];

    ## Iteratively ensure that n2 is a unit vector, and
    ## that dn is of length mu_nn w.r.t. the sky metric.
    cycles = 9;
    do
      dn .*= sqrt(mu_nn / dot(dn, g_nn * dn));
      n2 = n1 + dn;
      n2 ./= norm(n2);
      dn = n2 - n1;
      new_mu_nn = dot(dn, g_nn * dn);
    until --cycles < 0 || abs(mu_nn - new_mu_nn) < 1e-3 * mu_nn;
    
    ## Try a new random 2D offset if no convergence.
  until abs(mu_nn - new_mu_nn) < 1e-3 * mu_nn;
  mu_nn = new_mu_nn;

  ## Accounting for sky-frequency metric cross-terms:
  ## We require:
  ##   [dn;df]' * [g_nn,g_nf;g_nf',g_ff] * [dn;df] = mu
  ## Expanding the LHS:
  ##   dn'*g_nn*dn + 2*dn'*g_nf*df + df'*g_ff*df = mu
  ## The first term is equal to mu_nn:
  ##   2*dn'*g_nf*df + df'*g_ff*df = mu - mu_nn
  ## Suppose there is a vector dfo such that:
  ##   dn'*g_nf*df = dfo'*g_ff*df
  ## Then expand:
  ##   (df+dfo)'*g_ff*(df+dfo) = df'*g_ff*df + 2*dfo'*g_ff*df + dfo'*g_ff*dfo
  ##                           = mu - mu_nn + dfo'*g_ff*dfo
  ##                           = mu_ff
  ## Thus if we choose df such that the frequency-only mismatch
  ## equals mu_ff, then subtract dfo, the overall sky-frequency
  ## mismatch will equal mu, as required.
  dfo = g_ff' \ (g_nf' * dn);
  mu_ff = mu - mu_nn + dot(dfo, g_ff * dfo);

  ## Eigen-decompose frequency metric.
  [V_ff, D_ff] = eig(g_ff);

  ## Create a random frequency offset, scaled to be isotropically
  ## distributed on the surface of the frequency metric ellipsoid,
  ## and with a mismatch of mu_ff.
  df = inv(sqrt(D_ff)) * randn(length(f1), 1);
  df .*= sqrt(mu_ff ./ dot(df, D_ff * df));
  df = V_ff * df;

  ## Correct for sky-frequency metric cross terms.
  df = df - dfo;

  ## Create super-sky coordinate points.
  s1 = [n1; f1(:)];
  s2 = [n2; f1(:) + df];

endfunction
