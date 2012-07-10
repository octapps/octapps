function sensFact = SensFactStackSlide ( varargin )
  %% estimate 'StackSlide' sensitivity factor
  %% input arguments:
  %% 'Nseg':    	number of StackSlide segments
  %% 'Tdata':   	total amount of data used, in seconds
  %% 'misHist': 	mismatch histogram, produced using addDataToHist()
  %% 'pFD':     	false-dismissal probability = 1 - pDet
  %% 'pFA':     	false-alarm probability (-ies) to compute sensitivity at
  %% 'detectors': 	string containing detector-network to use 'H'=Hanford, 'L'=LIGO, 'V'=Virgo

  %% ----- parse commandline
  uvar = parseOptions ( varargin,
                       {'Nseg', 'scalar', 1 },		%% number of StackSlide segments
                       {'Tdata', 'scalar' },  		%% total amount of data used, in seconds
                       {'misHist', 'struct' },		%% mismatch histogram, produced using addDataToHist()
                       {'pFD', 'scalar', 0.1},		%% false-dismissal probability = 1 - pDet
                       {'pFA', 'vector', 0.01},		%% false-alarm probability (-ies) to compute sensitivity at
                       {'detectors', 'char', "HL" }	%% string containing detector-network to use 'H'=Hanford, 'L'=LIGO, 'V'=Virgo
                       );

  Rsqr = SqrSNRGeometricFactorHist("detectors", uvar.detectors, "mism_hgrm", uvar.misHist);
  rho = SensitivitySNR ( uvar.pFD, uvar.Nseg, Rsqr, "ChiSqr", "paNt", uvar.pFA );

  TdataSeg = uvar.Tdata / uvar.Nseg;
  sensFactInv = 5/2 * rho * TdataSeg^(-1/2);

  sensFact = 1 ./ sensFactInv;

  return;

endfunction
