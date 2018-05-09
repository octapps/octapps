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
## @deftypefn {Function File} {@var{num_SFTs} =} GetNumSFTsFromFile ( @var{sftfile} )
##
## safety measure to work around @command{lalapps_dumpSFT} bug: check if sftfile is a pattern matching several files, and if it is, just use the first one.
##
## @end deftypefn

function num_SFTs = GetNumSFTsFromFile ( sftfile )

  [status, output] = system(["find ", sftfile]);
  sftfiles = strsplit(output,"\n");

  sft_counting_string_from_header = "Locator:";

  [status, output] = system(["lalapps_dumpSFT --SFTfiles=", sftfiles{1}, " | grep -c ", sft_counting_string_from_header]);

  num_SFTs = str2num(output);

endfunction ## GetNumSFTsFromFile()

%!test disp("no test exists for this function as it requires access to data not included in OctApps")
