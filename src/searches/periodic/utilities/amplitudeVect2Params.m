function Amp = amplitudeVect2Params ( Amu )
  %% compute amplitude-vector {A^mu} from (MLDC) amplitudes {Amplitude, Inclination, Polarization, InitialPhase }
  %% Adapted from algorithm in LALEstimatePulsarAmplitudeParams()
  %% Amu is a row-vector for each signal, multiple signals being stored in multiple rows ,
  %% the resulting fields in Amp are also column-vectors for multiple signals

  [ rows0, cols0 ] = size ( Amu );
  if ( cols0 != 4 )
    error ("Amu has to contains 4-columns [ A1, A2, A3, A4 ]! \n");
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

  %% compute amplitude params in LIGO conventions first
  psi  = 0.5 * atan ( b1 ./  b2 ); %% in [-pi/4,pi/4] (gauge used also by TDS)
  phi0 =       atan ( b2 ./ b3 );  %% in [-pi/2,pi/2]

  %% Fix remaining sign-ambiguity by checking sign of reconstructed A1
  A1check = aPlus .* cos(phi0) .* cos(2.0*psi) - aCross .* sin(phi0) .* sin(2*psi);
  indsFlip = find ( A1check .* A1 < 0 );
  phi0(indsFlip) += pi;

  h0 = aPlus + sqrt ( disc );
  cosi = aCross ./ h0;

  %% Finally convert LIGO conventions -> MLDC conventions
  %% in order to get a *unique* result, we need to restrict the gauge
  %% of {Polarization, InitialPhase} to: InitialPhase in [0, 2pi), and
  %% Polarization in [0, pi/2 ): this can always be achieved by applying
  %% the gauge-transformations: (Polarization += pi/2) && (InitialPhase += pi)
  Amp.Amplitude    = 0.5 * h0;
  Amp.Inclination  = pi - acos(cosi);

  Polarization = mod( pi/2 - psi, pi );		%% in [0, pi): inv under += pi
  InitialPhase = phi0 + pi;			%% FIXME: Mystery sign-flip!

  flipInds = find ( Polarization >= pi/2 );
  Polarization(flipInds) -= pi/2;		%% now in [0, pi/2)
  InitialPhase(flipInds) += pi;

  InitialPhase = mod ( InitialPhase, 2*pi );	%% in [0, 2pi) inv under += 2pi

  Amp.Polarization  = Polarization;
  Amp.InitialPhase  = InitialPhase;

  return;

endfunction %% amplitudeVect2Params()
