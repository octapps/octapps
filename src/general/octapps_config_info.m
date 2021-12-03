## Copyright (C) 2021 Reinhard Prix
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
## @deftypefn {Function File} {} octapps_config_info
##
## Backwards compatible replacement for 'octave_config_info()' function, which
## in newer octave versions has been renamed to '__octave_config_info__()'
## see https://octave.org/doc/v6.4.0/Obsolete-Functions.html#Obsolete-Functions
##
## @end deftypefn

function val = octapps_config_info(option=[])

  cfginfo = "octave_config_info";
  if exist(cfginfo) != 5
    cfginfo = "__octave_config_info__";
    assert(exist(cfginfo) == 5)
  endif
  cfginfo_fun = str2func(cfginfo);

  if !isempty(option)
    val = cfginfo_fun(option);
  else
    val = cfginfo_fun();
  endif

endfunction
%!test
%!  octapps_config_info();
