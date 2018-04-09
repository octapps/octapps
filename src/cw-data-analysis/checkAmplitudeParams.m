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
## @deftypefn {Function File} { [ @var{convention}, @var{numSignals} ] =} checkAmplitudeParams ( @var{Amp} )
##
## check syntactic correctness of amplitude-parameter struct,
## and determine its convention: "LIGO" || "MLDC", depending
## on whether fields @{Amplitude, Inclination, Polarization, InitialPhase@},
## or @{h0, cosi, psi, phi0@} are present.
## The presence of both types of fields is an error.
##
## @end deftypefn

function [ convention, numSignals ] = checkAmplitudeParams ( Amp )

  have_Amp = isfield ( Amp, "Amplitude" );
  have_Inc = isfield ( Amp, "Inclination" );
  have_Pol = isfield ( Amp, "Polarization" );
  have_Ini = isfield ( Amp, "InitialPhase" );

  have_h0  = isfield ( Amp, "h0" );
  have_cosi= isfield ( Amp, "cosi" );
  have_psi = isfield ( Amp, "psi" );
  have_phi0= isfield ( Amp, "phi0" );

  convention = [];
  if ( have_Amp || have_Inc || have_Pol || have_Ini )
    if ( have_Amp && have_Inc && have_Pol && have_Ini )
      convention = "MLDC";

      ## make sure the input vectors have the required shape
      [rows1, cols1 ] = size ( Amp.Amplitude );
      [rows2, cols2 ] = size ( Amp.Inclination );
      [rows3, cols3 ] = size ( Amp.Polarization );
      [rows4, cols4 ] = size ( Amp.InitialPhase );

      if ( cols1 != 1 || cols2 != 1 || cols3 != 1 || cols4 != 1 )
        error ("Amplitude params must be Nx1 column vectors!\n");
      endif
      if ( rows1 != rows2 || rows1 != rows3 || rows1 != rows4 )
        error ("Amplitude params must be Nx1 column vectors of identical length!\n");
      endif
      numSignals = rows1;

    else
      error ("Incomplete amplitude parameters: Need {Amplitude, Inclination, Polarization, InitialPhase }!\n");
    endif
  endif

  if ( have_h0 || have_cosi || have_psi || have_phi0 )
    if ( !isempty(convention) )
      error ("Ambiguous convention: use either LIGO {h0,cosi,..} or MLDC {Amplitude, Inclination, ...}!\n");
    endif
    if ( have_h0 && have_cosi && have_psi && have_phi0 )
      convention = "LIGO";

      ## make sure the input vectors have the required shape
      [rows1, cols1 ] = size ( Amp.h0 );
      [rows2, cols2 ] = size ( Amp.cosi );
      [rows3, cols3 ] = size ( Amp.psi );
      [rows4, cols4 ] = size ( Amp.phi0 );

      if ( cols1 != 1 || cols2 != 1 || cols3 != 1 || cols4 != 1 )
        error ("Amplitude params must be Nx1 column vectors!\n");
      endif
      if ( rows1 != rows2 || rows1 != rows3 || rows1 != rows4 )
        error ("Amplitude params must be Nx1 column vectors of identical length!\n");
      endif
      numSignals = rows1;

    else
      error ("Incomplete amplitude parameters: Need {h0, cosi, psi, phi0 }!\n");
    endif
  endif

  return;

endfunction ## checkAmplitudeParams()

%!assert(checkAmplitudeParams(struct("h0", 1e-24, "cosi", 0, "psi", pi/4, "phi0", pi/5)), "LIGO")
