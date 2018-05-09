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
## @deftypefn {Function File} { [ @var{sfts}, @var{firstsft}, @var{sfts_cell} ] =} get_EatH_sft_paths ( @var{sftdir}, @var{filenamebit}, @var{sft_width}, @var{sftstartfreq}, @var{num_sfts_to_load}, @var{IFO} )
##
## function to get the full SFT paths (assuming Atlas-like directory structure)
## and cat them into argument strings for, e.g., @command{lalapps_ComputePSD}
## and also return first single SFT file path
## and a cell array of all SFT paths
##
## @end deftypefn

function [sfts, firstsft, sfts_cell] = get_EatH_sft_paths ( sftdir, filenamebit, sft_width, sftstartfreq, num_sfts_to_load, IFO )

  ## if SMALL_EPS not already defined globally, use a reasonable local default
  if ( isglobal("SMALL_EPS") )
    global SMALL_EPS;
  else
    SMALL_EPS = 1.0e-6;
  endif

  sfts = [];

  if ( !isdir(sftdir) )
    error(["Input sftdir='", sftdir, "' is not a valid directory."]);
  elseif ( isdir([sftdir, filesep, IFO]) ) ## e.g. S5 SFTs on atlas are structured in H1, L1 subdirs
    sftdir = [sftdir, filesep, IFO];
  elseif ( isdir([sftdir, filesep, toupper(IFO)]) )
    sftdir = [sftdir, filesep, toupper(IFO)];
  endif

  for numsft = 1:1:num_sfts_to_load

    currfreqstring = sprintf("%07.2f", sftstartfreq + (numsft-1)*sft_width); ## SFT files have format like "0050.00"

    sftfile = [sftdir, filesep, IFO, "_", currfreqstring, filenamebit];
    if ( exist(sftfile,"file") != 2 )
      freqsubdir = sprintf("%04.0f", 10*floor((sftstartfreq + (numsft-1)*sft_width)/10+SMALL_EPS)); ## e.g. S6 SFTs on atlas are organized in subdirs like "0050" - SMALL_EPS is to make sure 60.000 gets floored to 60 and not 50, as octave can have small numerical inaccuracies here
      sftfile = [sftdir, filesep, freqsubdir, filesep, IFO, "_", currfreqstring, filenamebit];
      if ( exist(sftfile,"file") != 2 )
        error(["Required SFT file ", sftfile, " does not exist."]);
      endif
    endif
    sfts = strcat(sfts, sftfile);
    if ( numsft == 1 )
      firstsft = sftfile;
    endif
    sfts_cell{numsft} = sftfile;

    if ( numsft < num_sfts_to_load )
      sfts = [sfts, ";"];
    endif

  endfor ## numsft = 1:1:num_sfts_to_load

endfunction ## get_EatH_sft_paths()

%!test disp("no test exists for this function as it requires access to data not included in OctApps")
