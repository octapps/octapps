function Amu = amplitudeParams2Vect ( Amp )
  %% compute the amplitude-vector {A^mu} for given amplitude-params, which can follow
  %% EITHER the MLDC convention {Amplitude, Inclination, Polarization, IntialPhase },
  %% OR in LIGO convention {h0, cosi, psi, phi0}: this will be auto-detected and properly
  %% converted.
  %% multiple signals must correspond to different *lines* in those fields, i.e. column-vectors!
  %% the output consists of 4D line vectors Amu(,1:4), multiple lines corresponding to multiple signals


  convention = checkAmplitudeParams ( Amp );

  %% if neccessary: convert LISA-conventions to LIGO conventions
  if ( strcmp ( convention, "MLDC" ) )
    in.h0 = 2 * Amp.Amplitude;
    in.cosi = - cos ( Amp.Inclination );
    in.psi = pi/2 - Amp.Polarization ;
    in.phi0 = Amp.InitialPhase + pi; 	%% FIXME: Mystery sign flip
  else
    in = Amp;
  endif

  Aplus  = 0.5 * in.h0 .* ( 1 + in.cosi.^2 );
  Across = in.h0 .* in.cosi;

  %% use standard expression for Amu in terms of (LIGO) amplitude-params
  cosphi  = cos(in.phi0);
  sinphi  = sin(in.phi0);
  cos2psi = cos(2*in.psi);
  sin2psi = sin(2*in.psi);

  Amu(:,1) =  Aplus .* cosphi .* cos2psi - Across .* sinphi .* sin2psi;
  Amu(:,2) =  Aplus .* cosphi .* sin2psi + Across .* sinphi .* cos2psi;
  Amu(:,3) = -Aplus .* sinphi .* cos2psi - Across .* cosphi .* sin2psi;
  Amu(:,4) = -Aplus .* sinphi .* sin2psi + Across .* cosphi .* cos2psi;

  return;

endfunction %% amplitudeParams2Vect()

