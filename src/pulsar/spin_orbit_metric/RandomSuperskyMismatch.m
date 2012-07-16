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

function [s1, s2] = RandomSuperskyMismatch(mu, g_ss, f1)

  ## Check input
  mu = mu(:)';
  assert(all(mu > 0));
  assert(size(g_ss, 1) == size(g_ss, 2));
  assert(length(f1) == size(g_ss, 1) - 3);

  ## Split super-sky metric into sky-only, frequency-only, and cross metrics
  g_nn = g_ss(1:3, 1:3);
  g_nf = g_ss(1:3, 4:end);
  g_ff = g_ss(4:end, 4:end);

  ## Choose random mismatches for the sky part
  mu_nn = rand(size(mu)) .* mu;

  ## Choose a random sky coordinate on the sky sphere
  n1 = randn(3, length(mu));
  norms = norm(n1, "cols");
  n1(1,:) ./= norms;
  n1(2,:) ./= norms;
  n1(3,:) ./= norms;

  ## Compute the vector perpendicular to the metric ellipsoid surface at n1
  np = 2 * g_nn * n1;
  norms = norm(np, "cols");
  np(1,:) ./= norms;
  np(2,:) ./= norms;
  np(3,:) ./= norms;

  ii = true(size(mu));
  dn = n2 = zeros(size(n1));
  new_mu_nn = zeros(size(mu));
  cycle = 0;
  do

    ## Create a random sky offset vector perpendicular to n1, i.e. in the tangent plane
    if cycle == 0
      dn(:,ii) = randn(3, sum(ii));
      dotratio = dot(dn(:,ii), np(:,ii)) ./ dot(np(:,ii), np(:,ii));
      dn(1,ii) -= dotratio .* np(1,ii);
      dn(2,ii) -= dotratio .* np(2,ii);
      dn(3,ii) -= dotratio .* np(3,ii);
    endif

    ## Rescale the sky offset vector to give a sky mismatch of mu_nn
    rescale = sqrt(mu_nn(ii) ./ dot(dn(:,ii), g_nn * dn(:,ii)));
    dn(1,ii) .*= rescale;
    dn(2,ii) .*= rescale;
    dn(3,ii) .*= rescale;

    ## Create a second random sky coordinate by adding the offset
    n2(:,ii) = n1(:,ii) + dn(:,ii);
    norms = norm(n2(:,ii), "cols");
    n2(1,ii) ./= norms;
    n2(2,ii) ./= norms;
    n2(3,ii) ./= norms;

    ## Recompute the offset between sky coordinates, and their sky mismatch
    dn(:,ii) = n2(:,ii) - n1(:,ii);
    new_mu_nn(ii) = dot(dn(:,ii), g_nn * dn(:,ii));

    ## Loop until the mismatch is close enough to what was asked for
    ii = abs(mu_nn - new_mu_nn) > 1e-3 * mu_nn;
    cycle = mod(cycle + 1, 10);
  until !any(ii)
  mu_nn = new_mu_nn;

  ## Frequency offset to account for sky-frequency metric cross-terms
  df_offset = g_ff' \ (g_nf' * dn);

  ## Target mismatch for frequency, so that overall mismatch is mu
  mu_ff = mu - mu_nn + dot(df_offset, g_ff * df_offset);

  ## Eigen-decompose frequency metric
  [V_ff, D_ff] = eig(g_ff);

  ## Create a random isotropically-distributed frequency offset
  df = -1 + 2 * rand(size(g_ff, 1), length(mu));
  for i = 1:size(df, 1)
    df(i,:) ./= sqrt(g_ff(i,i));
  endfor
  df = V_ff * df;

  ## Rescale frequency offset to get frequency mismatch of mu_ff
  rescale = sqrt(mu_ff ./ dot(df, g_ff * df));
  for i = 1:size(df, 1)
    df(i,:) .*= rescale;
  endfor

  ## Correct for sky-frequency cross terms
  df = df - df_offset;

  ## Create super-sky coordinate points
  f1 = f1(:);
  f1 = f1(:,ones(length(mu),1));
  s1 = [n1; f1];
  s2 = [n2; f1 + df];

endfunction
