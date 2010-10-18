%% Compute the probability/cumulative density functions
%% of the non-central chi-squared distribution.
%% Syntax:
%%   pdf = ncchisquare("pdf", k, lambda, x)
%%   cdf = ncchisquare("cdf", k, lambda, x)
%% where:
%%   k      = number of degrees of freedom
%%   lambda = non-centrality parameter
%%   x      = value of the non-central 
%%            chi-squared variable

%%
%%  Copyright (C) 2010 Karl Wette
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%

function p = ncchisquare(name, k, halflamb, x)

  %% check distribution name
  switch name
    case {"pdf", "cdf"}
      chi2 = ["chi2" name];
    otherwise
      error(["Invalid distribution type'" name "'!"]);
  endswitch

  %% divide lambda (input argument) by 2 to get "half of lambda"
  halflamb /= 2;

  %% check for common size input
  [errcode, k, halflamb, x] = common_size(k, halflamb, x);
  if errcode > 0
    error("Input arguments must be either of common size or scalars");
  endif

  %% flatten input after saving sizes
  siz = size(k);
  nel = prod(siz);
  k = k(:)';
  halflamb = halflamb(:)';
  x = x(:)';

  %% compute 10 series elements at a time
  Nstep = 10;

  %% set up matrices to compute series of non-central chi-squared distribution
  %% rows are elements of the series, columns map to (flattened) input values
  N = (0:Nstep-1)'(:, ones(nel, 1));
  k = k(ones(Nstep,1), :);
  halflamb = halflamb(ones(Nstep,1), :);
  x = x(ones(Nstep,1), :);

  %% add up series
  p = zeros(1, size(N, 2));
  err = inf;
  do

    %% compute element of series of non-central chi-squared distribution
    pN = sum(poisspdf(N, halflamb) .* feval(chi2, x, k + 2*N), 1);

    %% if this is not the first iteration, see if we should stop
    if N(1,1) > 0
      Nmax = N(end,1);
      err = max(reshape(abs(pN) ./ abs(p), 1, []));
    endif

    %% add computed elements to total, and increment element indices
    p += pN;
    N += Nstep;

    %% loop until maximum error is small enough
  until err <= 1e-4

  %% reshape output to original size of input
  p = reshape(p, siz);

endfunction
