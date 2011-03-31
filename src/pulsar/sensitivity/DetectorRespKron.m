%% Calculate the Kronecker product of the detector response
%% matrix in the celestial frame, integrated over time
%% and averaged over the given detectors.
%% Syntax:
%%   RcRc = DetectorRespKron(Tc,     Ws, phis, det, det, ...)
%%   RcRc = DetectorRespKron(Tc=inf, [], [],   det, det, ...)
%% where:
%%   det  = {slat, long, gamm, zeta}
%%   det  = "name"
%% and:
%%   RcRc   = common coefficients of "F{p,x}^2"
%%   Tc     = coherent integration time
%%   Ws     = sidereal period
%%   phis   = angle between zero meridian and the vernal 
%%            point at the *centre* of integration span
%%   slat   = sin of latitude of interferometer location (in rad. North)
%%   long   = longitude of interferometer location (in rad. East)
%%   gamm   = angle from local East to interferometer arms bisector (in rad.)
%%   zeta   = angle between interferometer arms
%%   "name" = name of a gravitational wave interferometer
function RcRc = DetectorRespKron(Tc, Ws, phis, varargin)

  %% if Tc is infinity, calculate limit as Tc->inf,
  %% in which case the sinc term is zero, and
  %% the cosine and sine terms don't matter.
  if isinf(Tc)
    cTcWs_2 = 0;
    sTcWs_2 = 0;
    sincTcWs_2 = 0;
    phis = 0;
  else
    TcWs_2 = Tc * Ws / 2;
    cTcWs_2 = cos(TcWs_2);
    sTcWs_2 = sin(TcWs_2);
    sincTcWs_2 = sTcWs_2 / TcWs_2;
  endif
  cphis = cos(phis);
  sphis = sin(phis);

  %% parse detectors in the remaining input
  if length(varargin) == 0
    error("Need at least one detector!");
  endif
  IFOs = cell(1, length(varargin));
  for i = 1:length(varargin)
    if ischar(varargin{i})
      [IFOs{i}.slat, IFOs{i}.long, IFOs{i}.gamm, IFOs{i}.zeta] = DetectorInfo(varargin{i});
    elseif length(varargin{i}) == 4
      [IFOs{i}.slat, IFOs{i}.long, IFOs{i}.gamm, IFOs{i}.zeta] = deal(varargin{i}{:});
    else
      error("Invalid input argument #%i!", i);
    endif
  endfor

  %% calculate values of the function g:
  %%   g(n+1,m+1) = integral of sin(Ws*t)^n*cos(Ws*t)^m/Tc, t from -Tc/2 to Tc/2
  g = nan(5,5);
  g(0+1,0+1) = 1;
  g(0+1,1+1) = sincTcWs_2;
  for m = 2:4
    g(0+1,m+1) = 1/m * cTcWs_2^(m-1) * sincTcWs_2 + (m-1)/m * g(0+1,(m-2)+1);
  endfor
  for m = 0:4
    g(1+1,m+1) = 0;
  endfor
  for n = 2:4
    for m = 0:4
      g(n+1,m+1) = 1/2/(m+n) * cTcWs_2^(m+1) * sTcWs_2^(n-2) * sincTcWs_2 * ((-1)^(n-1) - 1) + ...
          (n-1)/(n+m) * g((n-2)+1,m+1);
    endfor
  endfor

  %% calculate values of the function f:
  %%   f(n+1,m+1) = integral of sin(Ws*t+phis)^n*cos(Ws*t+phis)^m/Tc, t from -Tc/2 to Tc/2
  %% where
  %%   n + m <= 4
  f = nan(5,5);
  for n = 0:4
    for m = 0:4-n
      f(n+1,m+1) = 0;
      for i = 0:n
	for j = 0:m
	  f(n+1,m+1) += bincoeff(n,i)*bincoeff(m,j) * (-1)^j * ...
	      sphis^(i+j)*cphis^(n+m-i-j) * g((n-i+j)+1,(m+i-j)+1);
	endfor
      endfor
    endfor
  endfor

  %% calculate values of the coefficients Cn:
  %%   Cn(i,j,k,l) = integral of Cn(i)*Cn(j)*Cn(k)*Cn(l)/Tc, t from -Tc/2 to Tc/2
  %%               = f(n,m)
  %% where:
  %%   n is the number of indices in (i,j,k,l) which equal 1
  %%   m is the number of indices in (i,j,k,l) which equal 2
  Cn = zeros(3,3,3,3);
  ss = 1:numel(Cn);
  ii = zeros(length(ss), length(size(Cn)));
  [ii(:,1), ii(:,2), ii(:,3), ii(:,4)] = ind2sub(size(Cn), ss);
  nn = sum(ii == 1, 2);
  mm = sum(ii == 2, 2);
  nnmm = sub2ind(size(f), nn+1, mm+1);
  Cn(ss) = f(nnmm);
  Cn(abs(Cn) < eps) = 0;    % round very small values to zero

  %% calculate the Kronecker product of the detector response
  RcRc = zeros(9,9);
  for ifo = 1:length(IFOs)
    IFO = IFOs{ifo};
    
    %% detector response matrix w.r.t. the detector frame
    %% (for interferometer, x axis is along arm bisector)
    Rd = zeros(3,3);
    Rd(1,2) = Rd(2,1) = -sin(IFO.zeta) / 2;
    RdRd = kron(Rd, Rd);
      
    %% create random parameter generator
    rng = CreateRandParam(IFO.slat, IFO.long, IFO.gamm);

    %% calculate detector response for this detector
    %% if needed, Monte Carlo integrate over slat, long, gamm, zeta
    N = !!rng.allconst + !rng.allconst*2000;
    M = 0;
    RcRcdet = RcRcdetsqr = err = zeros(9,9);
    do
      
      %% next values of parameters
      [slat, long, gamm] = NextRandParam(rng, N);
      
      %% derived values
      clat  = sqrt(1 - slat.^2);
      cgamm = cos(gamm);
      sgamm = sin(gamm);

      %% calculate components of the transformation from the celestial frame
      %% to the detector frame, Mcdn, such that the complete transformation is:
      %%   Mcd = sum of Cn(i)*Mcdn(:,:,i), i from 1 to 3
      %% where
      %%   Cn  = [sin(Ws*t + phis), cos(Ws*t + phis), 1]
      Mcdn = zeros(3,3,N,3);
      eulr = zeros(3,3,N,4);
      for q = 0:3
	eulr(:,:,:,q+1) = 1/2*EulerRotation(
					    cos(long + q*pi/2), sin(long + q*pi/2),
					    slat,  clat,     % c/s of (pi/2 - latitude)
					    cgamm, sgamm
 					    );
      endfor
      Mcdn(:,:,:,1) = eulr(:,:,:,2+1) - eulr(:,:,:,0+1);
      Mcdn(:,:,:,2) = eulr(:,:,:,1+1) - eulr(:,:,:,3+1);
      Mcdn(:,:,:,3) = eulr(:,:,:,1+1) + eulr(:,:,:,3+1);

      %% calculate the Kronecker products of the components of 
      %% the transformation from the celestial frame
      McdnMcdn = zeros(9,9,N,3,3);
      for i = 1:3
	for j = 1:3
	  McdnMcdn(:,:,:,i,j) = matmap(@kron, Mcdn(:,:,:,i), Mcdn(:,:,:,j));
	endfor
      endfor

      %% calculate the Kronecker product of the response matrix:
      %%   RcRc = sum of Cn(i,j,k,l) * (Mcdn(:,:,i) K Mcdn(:,:,j))T *
      %%                   (Rd K Rd) * (Mcdn(:,:,k) K Mcdn(:,:,l)), i,j,k,l from 1 to 3
      RcRcdetN = zeros(9,9,N);
      for i = 1:3
	for j = 1:3
	  for k = 1:3
	    for l = 1:3
	      RcRcdetN += Cn(i,j,k,l) * matmap(".'*", McdnMcdn(:,:,:,i,j),
					       matmap("*", RdRd, McdnMcdn(:,:,:,k,l)));
	    endfor
	  endfor
	endfor
      endfor
      RcRcdetN(abs(RcRcdetN) < eps) = 0;    % round very small values to zero

      %% add to running total of RcRcdet and RcRcdet.^2
      RcRcdet    += sum  (RcRcdetN, 3);
      RcRcdetsqr += sumsq(RcRcdetN, 3);
      
      %% advance number of Monte Carlo integration points
      M += N;
 
      %% calculate Monte Carlo integration error
      err = sqrt((RcRcdetsqr / M) - (RcRcdet / M).^2) / sqrt(M);
      maxerr = max(err(:));
      
      %% continue until error is small enough
      %% (exit after 1 iteration if all parameters are constant)
    until (rng.allconst || maxerr < 1e-3)

    %% Kronecker product of detector response
    RcRcdet /= M;

    %% set to zero elements which are zero to within the integration error
    RcRcdet(abs(RcRcdet) < abs(err)) = 0;

    %% add to overall Kronecker product of detector response
    RcRc += RcRcdet;

  endfor

  %% average over detectors
  RcRc /= length(IFOs);
    
endfunction
