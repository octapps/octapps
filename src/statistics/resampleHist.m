%% Resamples a histogram to a new bin set.
%% Syntax:
%%   hgrm = resampleHist(hgrm, newdx)
%%   hgrm = resampleHist(hgrm, newbins)
%% where:
%%   hgrm    = histogram struct
%%   newdx   = new bin width (bins are generated)
%%   newbins = new bin set

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

function hgrm = resampleHist(hgrm, arg)

  %% parse input argument and get/generate bins
  if isscalar(arg)
    newxb = min(hgrm.xb):arg:max(hgrm.xb);
  else
    newxb = sort(arg(:)');
  endif

  %% enlarge old histogram by up to one
  %% bin either side, if needed, so that
  %% old/new histograms have the same range
  if hgrm.xb(1) != newxb(1)
    hgrm.xb = [min(hgrm.xb(1), newxb(1)), hgrm.xb];
    hgrm.px = [0,                         hgrm.px];
  endif
  if hgrm.xb(end) != newxb(end)
    hgrm.xb = [hgrm.xb, max(hgrm.xb(end), newxb(end))];
    hgrm.px = [0,       hgrm.px                      ];
  endif

  %% loop over new probability densities
  newpx = zeros(1, length(newxb) - 1);
  for i = 1:length(newpx)

    %% width of current new bin
    newxbwidth = newxb(i+1) - newxb(i);

    %% lookup old bins which intersect
    %% this bew bin and loop over them
    jrng = lookup(hgrm.xb, [newxb(i), newxb(i+1)]);
    for j = min(jrng):max(jrng)

      %% overlap of old/new histograms bins
      overlap = min(hgrm.xb(j+1), newxb(i+1)) - max(hgrm.xb(j), newxb(i));
      
      %% add to new probability density
      newpx(i) += hgrm.px(j) * overlap / newxbwidth;

    endfor

  endfor

  %% return new histogram
  hgrm.xb = newxb;
  hgrm.px = newpx;

endfunction
