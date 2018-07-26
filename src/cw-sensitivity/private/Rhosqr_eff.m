## Copyright (C) 2018 Christoph Dreissigacker
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

## Helper function for SensitivityDepth()
##
## Calculate the effective non-centrality according to eq. 43 of LIGO-P1800198

function rhosqr_eff = Rhosqr_eff(Tdata, Depth, Rsqr_x, mism_x = 0)

  rhosqr_eff = ( 2 / 5 .*sqrt(Tdata)./Depth ).^2 .*Rsqr_x.*( 1 - mism_x );

endfunction
