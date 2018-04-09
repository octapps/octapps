## Copyright (C) 2011 Karl Wette
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
## @deftypefn {Function File} { [ @var{ap}, @var{ax} ] =} SignalAmplitudes ( @code{nonax}, @var{cosi} )
## @deftypefnx{Function File} {@var{apxnorm} =} SignalAmplitudes ( @code{nonax} )
##
## Calculate the amplitudes of each polarisation from a signal
## emitted by a particular emission mechanism:
## "@var{nonax}": nonaxisymmetric distortion at 2f
##
## @heading Arguments
##
## @table @var
## @item ap
## @itemx ax
## signal polarisation amplitudes
##
## @item apxnorm
## normalisation constant for R^2
##
## @item cosi
## cosine of the inclination angle
##
## @end table
##
## @end deftypefn

function varargout = SignalAmplitudes(emission, cosi)

  ## select an emission mechanism
  switch emission
    case "nonax"
      if nargout == 1
        apxnorm = 4/25;
        varargout = {apxnorm};
      else
        ap = 0.5.*(1 + cosi.^2);
        ax = cosi;
        varargout = {ap, ax};
      endif
    otherwise
      error("%s: invalid emission mechanism '%s'", funcName, emission)
  endswitch

endfunction

%!assert(SignalAmplitudes("nonax"), 4/25)
