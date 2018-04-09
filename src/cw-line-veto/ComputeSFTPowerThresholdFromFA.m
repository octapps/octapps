## Copyright (C) 2013 David Keitel
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

## -*- texinfo -*-
## @deftypefn {Function File} {@var{SFTpower_thresh} =} ComputeSFTPowerThresholdFromFA ( @var{SFTpower_fA}, @var{num_SFTs} )
##
## Compute SFT power threshold from a SFT power false alarm rate.
##
## @end deftypefn

function SFTpower_thresh = ComputeSFTPowerThresholdFromFA ( SFTpower_fA, num_SFTs )

  SFTpower_thresh = norminv ( 1.0 - SFTpower_fA, 1.0, 1.0/sqrt(num_SFTs) );

endfunction ## ComputeSFTPowerThresholdFromFA()

%!assert(ComputeSFTPowerThresholdFromFA(0.01, 100), 1.2326, 1e-3)
