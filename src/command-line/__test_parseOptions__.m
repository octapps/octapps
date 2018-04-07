## Copyright (C) 2018 Karl Wette
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
## @deftypefn
##
## Helper function for testing @command{parseOptions()} and related functions.
##
## @end deftypefn

function optstr = __test_parseOptions__(varargin)

  ## parse options
  opts = parseOptions(varargin,
                      {"real_strictpos_scalar", "real,strictpos,scalar"},
                      {"integer_vector", "integer,vector"},
                      {"string", "char"},
                      {"cell", "cell", {1;1;1}},
                      {"twobytwo", "rows:2,cols:2,+exactlyone:cell", eye(2)},
                      []);

  ## return string of all options
  optstr = stringify(opts);

endfunction
