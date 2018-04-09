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
## @deftypefn {Function File} {@var{Amp} =} amplitudeVect2Params ( @var{Amu}, @var{convention} )
##
## compute amplitude-vector @{A^mu@} from (MLDC) amplitudes @{Amplitude, Inclination, Polarization, InitialPhase @}
##
## Amu is a row-vector for each signal, multiple signals being stored in multiple rows ,
## the resulting fields in Amp are also column-vectors for multiple signals
## @itemize
## @item
## if convention == "LIGO", return @{h0,cosi,psi.iota@} and @{aPlus,aCross@},
## @item
## if convention == "MLDC" return @{Amplitude,Inclination,Polarization, InitialPhase@} using MLDC conventions
## @item
## the default = "LIGO" if not specified
## @end itemize
##
## @heading Note
## Adapted from algorithm in @command{LALEstimatePulsarAmplitudeParams()}
##
## @end deftypefn

function Amp = amplitudeVect2Params ( Amu, convention )

  [ rows0, cols0 ] = size ( Amu );
  if ( cols0 != 4 )
    error ("Amu has to contains 4-columns [ A1, A2, A3, A4 ]! \n");
  endif

  if ( exist("convention") )
    if ( strcmp ( convention, "MLDC") )
      isMLDC = true;
    elseif ( strcmp ( convention, "LIGO" ) )
      isMLDC = false;
    else
      error ("Convention must be either 'LIGO' or 'MLDC'.");
    endif
  else
    isMLDC = false;
  endif

  A1 = Amu(:,1);
  A2 = Amu(:,2);
  A3 = Amu(:,3);
  A4 = Amu(:,4);

  Asq = A1.^2 + A2.^2 + A3.^2 + A4.^2;
  Da = A1 .* A4 - A2 .* A3;

  disc = sqrt ( Asq.^2 - 4.0 * Da.^2 );

  Ap2  = 0.5 * ( Asq + disc );
  aPlus = sqrt(Ap2);

  Ac2 = 0.5 * ( Asq - disc );
  aCross = sign(Da) .* sqrt( Ac2 );

  beta = aCross ./ aPlus;

  b1 =   A4 - beta .* A1;
  b2 =   A3 + beta .* A2;
  b3 = - A1 + beta .* A4 ;

  ## compute amplitude params in LIGO conventions first
  psi  = 0.5 * atan2 ( b1,  b2 );  ## in [-pi/2,pi/2]
  phi0 =       atan2 ( b2,  b3 );  ## in [-pi, pi]

  ## Fix remaining sign-ambiguity by checking sign of reconstructed A1
  A1check = aPlus .* cos(phi0) .* cos(2.0*psi) - aCross .* sin(phi0) .* sin(2*psi);
  indsFlip = find ( A1check .* A1 < 0 );
  phi0(indsFlip) += pi;

  h0 = aPlus + sqrt ( disc );
  cosi = aCross ./ h0;

  if ( !isMLDC )
    ## ---------- Return LSC conventions

    ## make unique by fixing the gauge to be psi in [-pi/4, pi/4], phi0 in [0, 2*pi]
    while ( !isempty ( (inds = find ( psi > pi/4 )) ) )
      psi(inds) -= pi/2;
      phi0(inds) -= pi;
    endwhile
    while ( !isempty ( (inds = find ( psi < - pi/4 )) ) )
      psi(inds) += pi/2;
      phi0(inds) += pi;
    endwhile
    while ( !isempty ( (inds = find ( phi0 < 0 )) ) )
      phi0(inds) += 2 * pi;
    endwhile
    while ( !isempty ( (inds = find ( phi0 > 2 * pi )) ) )
      phi0(inds) -= 2 * pi;
    endwhile

    Amp.h0 = h0;
    Amp.cosi = cosi;
    Amp.phi0 = phi0;
    Amp.psi = psi;

    Amp.aPlus = aPlus;
    Amp.aCross = aCross;
  else
    ## ---------- Convert LIGO conventions -> MLDC conventions
    ## in order to get a *unique* result, we need to restrict the gauge
    ## of {Polarization, InitialPhase} to: InitialPhase in [0, 2pi), and
    ## Polarization in [0, pi/2 ): this can always be achieved by applying
    ## the gauge-transformations: (Polarization += pi/2) && (InitialPhase += pi)
    Amp.Amplitude    = 0.5 * h0;
    Amp.Inclination  = pi - acos(cosi);

    Polarization = mod( pi/2 - psi, pi );               ## in [0, pi): inv under += pi
    InitialPhase = phi0 + pi;                   ## FIXME: Mystery sign-flip!

    flipInds = find ( Polarization >= pi/2 );
    Polarization(flipInds) -= pi/2;             ## now in [0, pi/2)
    InitialPhase(flipInds) += pi;

    InitialPhase = mod ( InitialPhase, 2*pi );  ## in [0, 2pi) inv under += 2pi

    Amp.Polarization  = Polarization;
    Amp.InitialPhase  = InitialPhase;

  endif

  return;

endfunction ## amplitudeVect2Params()

%!shared A0
%!  A0 = 1e-24 * randn(1, 4);
%!assert(amplitudeParams2Vect(amplitudeVect2Params(A0, "LIGO")), A0, 1e-3)
%!assert(amplitudeParams2Vect(amplitudeVect2Params(A0, "MLDC")), A0, 1e-3)
