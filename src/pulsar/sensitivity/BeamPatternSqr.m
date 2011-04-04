%% Calculates a joint histogram of the squared
%% time-averaged beam patterns for a given detector network
%% Syntax:
%%   Fpxsqr = BeamPatternSqr(RcRc, alpha, sdelt, psi, "property", value, ...)
%% where:
%%   Rc     = Kronecker product of the detector network response
%%   alpha  = right ascension of source
%%   sdelt  = sine of declination of source
%%   psi    = polarisation angle of source
%%   Fpxsqr = joint histogram
%%
%%   optional allowed property-value pairs are
%%   "err"          = convergence requirement on histogram [default = 1e-2]
%%   "binsize"      = bin-size of resulting histogram [default = 0.01]

function hFpxsqr = BeamPatternSqr(RcRc, alpha, sdelt, psi, varargin)

  %% parse optional keywords, set defaults if not specified
  dx0 = 0.005;
  err0 = 1e-2;
  kv = keyWords ( varargin, "err", err0, "binsize", dx0 );

  %% plus and cross polarisation tensors in wave frame
  Hwp = [[1, 0, 0]; [0, -1, 0]; [0, 0, 0]];
  Hwx = [[0, 1, 0]; [1,  0, 0]; [0, 0, 0]];

  %% create random parameter generator
  rng = CreateRandParam(alpha, sdelt, psi);

  %% build up histogram over alpha, sdelt, psi
  N = !!rng.allconst + !rng.allconst*2000;
  hFpxsqr = newHist(2);
  RcRcN = RcRc(:,:,ones(N,1));
  do

    %% next values of parameters
    [alpha, sdelt, psi] = NextRandParam(rng, N);

    %% transform from wave to celestial frame
    Mwc = EulerRotation(
			cos(psi),  -sin(psi),            % c/s of (-psi)
			-sdelt,    -sqrt(1-sdelt.^2),    % c/s of (-pi/2 - delta)
			sin(alpha), cos(alpha)           % c/s of (pi/2 - alpha)
			);

    %% plus and cross polarisation tensors in celestial frame
    Hcp = matmap("*", Mwc, matmap("*.'", Hwp, Mwc));
    Hcx = matmap("*", Mwc, matmap("*.'", Hwx, Mwc));

    %% time-averaged squared beam patterns:
    %%   F{p,x}sqr = tr((Rc K Rc)T * (Hc{p,x} K Hc{p,x}))
    FpsqrN = squeeze(sum(sum(RcRcN .* matmap(@kron, Hcp, Hcp), 1), 2));
    FxsqrN = squeeze(sum(sum(RcRcN .* matmap(@kron, Hcx, Hcx), 1), 2));

    %% add new values to histogram
    oldhFpxsqr = hFpxsqr;
    hFpxsqr = addDataToHist(hFpxsqr, [FpsqrN, FxsqrN], kv.binsize);

    %% calculate difference between old and new histograms
    err = histMetric(hFpxsqr, oldhFpxsqr);

    %% continue until error is small enough
    %% (exit after 1 iteration if all parameters are constant)
  until (rng.allconst || err < kv.err )

  %% output histogram
  if rng.allconst
    hFpxsqr = newHist(2);
    hFpxsqr.xb{1} = FpsqrN(1);
    hFpxsqr.xb{2} = FxsqrN(1);
  else
    hFpxsqr = normaliseHist(hFpxsqr);
  endif

endfunction
