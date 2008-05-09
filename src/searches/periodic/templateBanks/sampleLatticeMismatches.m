%% mis = sampleLatticeMismatches ( dim, trials, lattice )
%%
%% return the result of 'trials' randomly generated mismatches in 'lattice'
%% in 'dim' dimensions, uniformly sampling the Wigner-Seitz (Voronoi) cell


%%
%% Copyright (C) 2008 Reinhard Prix
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

function mis = sampleLatticeMismatches ( dim, trials, lattice )

  [gen, rot] = LatticeGenerator ( dim, lattice );

  upZn = rand(dim, trials);
  up = gen * upZn;

  c = LatticeFindClosestPoint (up, lattice);
  relv = up - c;	%% vector shifted to origin

  mis0 = sumsq ( relv, 1 );

  %% properly rescale mismatches by maximum possible: = coveringRadius^2
  R = LatticeCoveringRadius ( dim, lattice );
  mis = mis0 / R^2;

  return;

endfunction
