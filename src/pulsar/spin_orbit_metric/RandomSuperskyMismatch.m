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

function [s1, s2] = RandomSuperskyMismatch(mu, g_ss, ss_scale, f1)

  ## Check input
  mu = mu(:);
  f1 = f1(:);
  assert(all(mu > 0));
  assert(size(g_ss, 1) == size(g_ss, 2));
  assert(length(ss_scale) == size(g_ss, 1));
  assert(length(f1) == size(g_ss, 1) - 3);

  ## Split super-sky metric into sky-only, frequency-only, and cross metrics
  g_nn = g_ss(1:3, 1:3);
  g_nf = g_ss(1:3, 4:end);
  g_ff = g_ss(4:end, 4:end);

  ## Choose random mismatches for the sky part
  mu_nn = rand(size(mu)) * mu;

  ## Choose a random sky coordinate on the sky sphere
  n1 = randn(3, 1);
  n1 /= norm(n1);
  n1 .*= ss_scale(1:3);

  ## Compute the vector perpendicular to the metric ellipsoid surface at n1
  np = 2 * g_nn * n1;

  ## Create a random sky offset vector perpendicular to n1, i.e. in the tangent plane
  dn = randn(size(np));
  dn = dn - dot(dn, np) / dot(np, np) .* np;

  do

    ## Rescale the sky offset vector to give a sky mismatch of mu_nn
    dn = dn * sqrt(mu_nn / (dn' * g_nn * dn));

    ## Create a second random sky coordinate by adding the offset
    n2 = n1 + dn;
    n2 /= norm(n2);
    n2 .*= ss_scale(1:3);
    
    ## Recompute the offset between sky coordinates, and their sky mismatch
    dn = n2 - n1;
    new_mu_nn = dn' * g_nn * dn;

    ## Loop until the mismatch is close enough to what was asked for
  until abs(mu_nn - new_mu_nn) < 1e-3 * mu_nn
  mu_nn = new_mu_nn;

  ## Frequency offset to account for sky-frequency metric cross-terms
  df_offset = g_ff' \ (g_nf' * dn);

  ## Target mismatch for frequency, so that overall mismatch is mu
  mu_ff = mu - mu_nn + (df_offset' * g_ff * df_offset);

  ## Eigen-decompose frequency metric
  [V_ff, D_ff] = eig(g_ff);

  ## Create a random isotropically-distributed frequency offset
  df = randn(size(g_ff, 1), 1);
  df = df ./ sqrt(diag(D_ff));
  df = V_ff * df;

  ## Rescale frequency offset to get frequency mismatch of mu_ff
  df = df * sqrt( mu_ff / (df' * g_ff * df) );

  ## Correct for sky-frequency cross terms
  df = df - df_offset;

  ## Create super-sky coordinate points
  s1 = [n1; f1];
  s2 = [n2; f1 + df];

endfunction
