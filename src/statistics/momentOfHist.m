%% Returns the moment of a histogram,
%% taken with respect to a given position.
%% Syntax:
%%   mu   = momentOfHist(hgrm, x0, n)
%% where:
%%   hgrm = histogram struct
%%   x0   = a given position in each dimension
%%   n    = moment orders in each dimension
%%   mu   = moment

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

function mu = momentOfHist(hgrm, x0, n)

  %% check input
  assert(isHist(hgrm));
  dim = length(hgrm.xb);
  assert(isvector(x0) && length(x0) == dim);
  assert(isvector(n)  && length(x0) == dim && all(n >= 0));

  shape = size(hgrm.px);

  %% calculate moments:
  %%   mu(n) = integrate over x{1} to x{dim} : 
  %%              px(x{1},...,x{dim}) * x{1}^n{1} * ... * x{dim}^n{dim} dx{1} ... dx{dim}
  
  %% start with probability array
  muint = hgrm.px;

  %% loop over dimensions
  for k = 1:dim

    %% get lower and upper bin boundaries
    [xl, xh] = histBinGrids(hgrm, k, "xl", "xh");

    %% integral term for kth dimension:
    %%    integrate x{k}^n dx{k}, x{k} over all bins in kth dimension
    muint .*= ((xh.^(n(k)+1) - xl.^(n(k)+1)) ./ (n(k)+1));
    
  endfor
  
  %% sum up integral to get final moment
  mu = sum(muint(:));

endfunction
