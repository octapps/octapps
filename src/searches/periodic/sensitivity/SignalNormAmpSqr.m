%% Calculates a joint histogram of the squared
%% normalised signal amplitudes
%% Syntax:
%%   apxsqr = SignalNormAmpSqr("nonax", cosi)
%% where:
%%   cosi   = cosine of the inclination angle
%%   apxsqr = [apsqr, axsqr],  if all parameters are constant
%%          = joint histogram, otherwise
function hapxsqr = SignalNormAmpSqr(name, varargin)

  %% check number of input arguments
  switch name
    case "nonax"
    otherwise
      error(["Invalid amplitude type '" name "'!"]);
  endswitch

  %% create random parameter generator
  rng = CreateRandParam(varargin{:});
  par = cell(size(varargin));
  
  %% build up histogram
  N = !!rng.allconst + !rng.allconst*1000;
  dx = 0.005;
  hapxsqr = newHist({2});
  apsqrN = axsqrN = zeros(N,1);
  do
    
    %% next values of parameters
    [par{:}] = NextRandParam(rng, N);

    %% calculate amplitude parameters
    switch name
      case "nonax"
	cosi   = par{1}(:);
	apsqrN = 1/4*(1 + cosi.^2).^2;
	axsqrN = cosi.^2;
    endswitch

    %% add new values to histogram
    oldhapxsqr = hapxsqr;
    hapxsqr = addDataToHist(hapxsqr, [apsqrN, axsqrN], dx);

    %% calculate difference between old and new histograms
    err = histMetric(hapxsqr, oldhapxsqr);

    %% continue until error is small enough
    %% (exit after 1 iteration if all parameters are constant)
  until (rng.allconst || err < 1e-2)

  %% output histogram
  if rng.allconst
    hapxsqr = newHist({2});
    hapxsqr.xb{1} = apsqrN(1);
    hapxsqr.xb{2} = axsqrN(1);
  else
    hapxsqr = normaliseHist(hapxsqr);
  endif

endfunction
