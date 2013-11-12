%% Copyright (C) 2013 David Keitel
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with with program; see the file COPYING. If not, write to the
%% Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%% MA  02111-1307  USA

function [sfts, firstsft] = get_EatH_sft_paths ( params_init, sftstartfreq, num_sfts_to_load, IFO )
 ## [sfts, firstsft] = get_sft_paths ( params_init, sftstartfreq, num_sfts_to_load, IFO )
 ## function to get the full SFT paths (assuming Atlas-like directory structure) and cat them into argument strings for lalapps_ComputePSD

 global SMALL_EPS;

 sfts = [];

 if ( !isdir(params_init.sftdir) )
  error(["Input sftdir='", params_init.sftdir, "' is not a valid directory."]);
 elseif ( isdir([params_init.sftdir, filesep, IFO]) ) # e.g. S5 SFTs on atlas are structured in H1, L1 subdirs
  params_init.sftdir = [params_init.sftdir, filesep, IFO];
 elseif ( isdir([params_init.sftdir, filesep, toupper(IFO)]) )
  params_init.sftdir = [params_init.sftdir, filesep, toupper(IFO)];
 endif

 for numsft = 1:1:num_sfts_to_load

  currfreqstring = sprintf("%07.2f", sftstartfreq + (numsft-1)*params_init.sft_width); # SFT files have format like "0050.00"

  sftfile = [params_init.sftdir, filesep, IFO, "_", currfreqstring, params_init.sft_filenamebit];
  if ( exist(sftfile,"file") != 2 )
   freqsubdir = sprintf("%04.0f", 10*floor((sftstartfreq + (numsft-1)*params_init.sft_width)/10+SMALL_EPS)); # e.g. S6 SFTs on atlas are organized in subdirs like "0050" - SMALL_EPS is to make sure 60.000 gets floored to 60 and not 50, as octave can have small numerical inaccuracies here
   sftfile = [params_init.sftdir, filesep, freqsubdir, filesep, IFO, "_", currfreqstring, params_init.sft_filenamebit];
   if ( exist(sftfile,"file") != 2 )
    error(["Required SFT file ", sftfile, " does not exist."]);
   endif
  endif
  sfts = [sfts, sftfile];
  if ( numsft == 1 )
   firstsft = sftfile;
  endif

  if ( numsft < num_sfts_to_load )
   sfts = [sfts, ";"];
  endif

 endfor # numsft = 1:1:num_sfts_to_load

endfunction # get_EatH_sft_paths()