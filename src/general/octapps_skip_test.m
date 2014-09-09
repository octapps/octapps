## Copyright (C) 2014 Karl Wette
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <http://www.gnu.org/licenses/>.

## Skip a test if it cannot be run, e.g. LALSuite wrappings are not available.
## Usage:
##   octapps_skip_test

function octapps_skip_test(msg)
  global octapps_skipped_tests;
  ++octapps_skipped_tests;
  printf("skipping test: %s\n", msg);
endfunction
