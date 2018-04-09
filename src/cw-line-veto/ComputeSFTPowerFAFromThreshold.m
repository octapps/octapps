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
## @deftypefn {Function File} {@var{SFTpower_fA} =} ComputeSFTPowerFAFromThreshold ( @var{SFTpower_thresh}, @var{num_SFTs} )
##
## Compute SFT power false alarm rate from a SFT power threshold.
##
## @end deftypefn

function SFTpower_fA = ComputeSFTPowerFAFromThreshold ( SFTpower_thresh, num_SFTs )

  SFTpower_fA = 1.0 - normcdf ( SFTpower_thresh, 1.0, 1.0/sqrt(num_SFTs) );

endfunction ## ComputeSFTPowerFAFromThreshold()

%!assert(ComputeSFTPowerFAFromThreshold(1.2326, 100), 0.01, 1e-3)
