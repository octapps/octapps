## Copyright (C) 2007 Reinhard Prix
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
## @deftypefn {Function File} {@var{Amu} =} amplitudeParams2Vect ( @var{Amp} )
##
## compute the amplitude-vector @{A^mu@} for given amplitude-params, which can follow
## @itemize
## @item
## either the MLDC convention @{Amplitude, Inclination, Polarization, IntialPhase @},
## @item
## or in LIGO convention @{h0, cosi, psi, phi0@}: this will be auto-detected and properly
## converted.
## @end itemize
## multiple signals must correspond to different *lines* in those fields, i.e. column-vectors!
## the output consists of 4D line vectors Amu(,1:4), multiple lines corresponding to multiple signals
##
## @end deftypefn

function Amu = amplitudeParams2Vect ( Amp )

  convention = checkAmplitudeParams ( Amp );

  ## if neccessary: convert LISA-conventions to LIGO conventions
  if ( strcmp ( convention, "MLDC" ) )
    in.h0 = 2 * Amp.Amplitude;
    in.cosi = - cos ( Amp.Inclination );
    in.psi = pi/2 - Amp.Polarization ;
    in.phi0 = Amp.InitialPhase + pi;    ## FIXME: Mystery sign flip
  else
    in = Amp;
  endif

  Aplus  = 0.5 * in.h0 .* ( 1 + in.cosi.^2 );
  Across = in.h0 .* in.cosi;

  ## use standard expression for Amu in terms of (LIGO) amplitude-params
  cosphi  = cos(in.phi0);
  sinphi  = sin(in.phi0);
  cos2psi = cos(2*in.psi);
  sin2psi = sin(2*in.psi);

  Amu(:,1) =  Aplus .* cosphi .* cos2psi - Across .* sinphi .* sin2psi;
  Amu(:,2) =  Aplus .* cosphi .* sin2psi + Across .* sinphi .* cos2psi;
  Amu(:,3) = -Aplus .* sinphi .* cos2psi - Across .* cosphi .* sin2psi;
  Amu(:,4) = -Aplus .* sinphi .* sin2psi + Across .* cosphi .* cos2psi;

  return;

endfunction ## amplitudeParams2Vect()

%!test
%!  p0 = struct("h0", 1e-24, "cosi", 0, "psi", pi/4, "phi0", pi/5);
%!  p = amplitudeVect2Params(amplitudeParams2Vect(p0));
%!  assert(p.h0, p0.h0, 1e-3);
%!  assert(p.cosi, p0.cosi, 1e-3);
%!  assert(p.psi, p0.psi, 1e-3);
%!  assert(p.phi0, p0.phi0, 1e-3);
