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
## @deftypefn {Function File} { [ @var{fkdot_epoch1}, @var{fkdotband_epoch1} ] =} ExtrapolatePulsarSpinRange ( @var{epoch0}, @var{epoch1}, @var{fkdot_epoch0}, @var{fkdotband_epoch0}, @var{numSpins} )
##
## function to translate spin-values \f$\f^@{(l)@}\f$ and bands from epoch0 to epoch1
## based on LALSuite programs/functions HierarchSearchGCT and LALExtrapolatePulsarSpinRange
##
## @heading Note
##
## different index conventions between lalapps and octave - (k) here corresponds to [k-1] in LALExtrapolatePulsarSpinRange, i.e. fkdot(1)=fkdot[0]=freq, fkdot(2)=fkdot(1)=f1dot, ...
##
## @end deftypefn

function [fkdot_epoch1, fkdotband_epoch1] = ExtrapolatePulsarSpinRange ( epoch0, epoch1, fkdot_epoch0, fkdotband_epoch0, numSpins )

  dtau = epoch1 - epoch0;

  for l = 0:1:numSpins

    flmin     = 0;
    flmax     = 0;
    kfact     = 1; ## values for k=0
    dtau_powk = 1; ## values for k=0

    for k = 0:1:numSpins-l

      fkltauk0 = fkdot_epoch0(k+l+1) * dtau_powk;
      fkltauk1 = fkltauk0 + fkdotband_epoch0(k+l+1) * dtau_powk;
      fkltauk_min = min ( fkltauk0, fkltauk1 );
      fkltauk_max = max ( fkltauk0, fkltauk1 );
      flmin += fkltauk_min / kfact;
      flmax += fkltauk_max / kfact;
      kfact *= (k+1);
      dtau_powk *= dtau;

    endfor ## k = 0:1:numSpins-l

    fkdot_epoch1(l+1)     = flmin;
    fkdotband_epoch1(l+1) = flmax - flmin;

  endfor ## l = 0:1:numSpins

endfunction ## ExtrapolatePulsarSpinRange()

%!assert(ExtrapolatePulsarSpinRange(800000000, 900000000, [100, -1e-8], [1e-2, 1e-8], 1), [99, 1e-8], 1e-3)
