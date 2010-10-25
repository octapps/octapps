%% Returns the moments of a histogram,
%% taken with respect to a given position.
%% Syntax:
%%   mu            = momentsOfHist(hgrm, x0, [n, n, ...])
%%   [mu, mu, ...] = momentsOfHist(hgrm, x0, [n, n, ...])
%% where:
%%   hgrm = histogram struct
%%   x0   = a given position
%%   n    = moment orders
%%   mu   = moments

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

function varargout = momentsOfHist(hgrm, x0, n)

  %% check input
  assert(isHist(hgrm));
  assert(isscalar(x0));
  assert(isvector(n));
  assert(all(n >= 0))';

  %% take moments with respect to x0
  hgrm.xb -= x0;

  %% calculate moments:
  %%   mu(n) = sum over all bins k of
  %%           px(k) * (integral of x^n, x from xb(k) to xb(k+1))
  mu = cell(size(n));
  for i = 1:length(n)
    mu{i} = sum((hgrm.xb(2:end).^(n(i)+1) - hgrm.xb(1:end-1).^(n(i)+1)) ./ (n(i)+1) .* hgrm.px);
  endfor

  %% output moments
  if nargout <= 1
    varargout = {[mu{:}]};
  elseif nargin == length(n)
    varargout = mu;
  else
    error("Invalid number of output arguments!");
  endif

endfunction
