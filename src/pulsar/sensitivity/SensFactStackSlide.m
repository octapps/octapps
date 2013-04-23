function sensFact = SensFactStackSlide ( varargin )
  %% estimate 'StackSlide' sensitivity factor
  %% input arguments:
  %% 'Nseg':    	number of StackSlide segments
  %% 'Tdata':   	total amount of data used, in seconds
  %% 'misHist': 	mismatch histogram, produced using addDataToHist()
  %% 'pFD':     	false-dismissal probability = 1 - pDet
  %% 'pFA':     	false-alarm probability (-ies) *per template* [can be a vector]
  %% 'detectors': 	string containing detector-network to use 'H'=Hanford, 'L'=Livingston, 'V'=Virgo
  %% 'alpha': source right ascension in radians (default: all-sky)
  %%  'delta': source declination (default: all-sky)
  %%

  %% ----- parse commandline
  uvar = parseOptions ( varargin,
                       {"Nseg", 'scalar', 1 },
                       {"Tdata", 'scalar' },
                       {"misHist", 'Hist' },
                       {"pFD", 'scalar', 0.1},
                       {"pFA", 'vector' },
                       {"detectors", 'char', "HL" },
                       {"alpha", 'numeric,vector', [0, 2*pi]},
                       {"delta", 'numeric,vector', [-1, 1]}
                       );

  Rsqr = SqrSNRGeometricFactorHist("detectors", uvar.detectors, "mism_hgrm", uvar.misHist, "alpha", uvar.alpha, "sdelta", sin(uvar.delta) );
  rho = SensitivitySNR ( uvar.pFD, uvar.Nseg, Rsqr, "ChiSqr", "paNt", uvar.pFA );

  TdataSeg = uvar.Tdata / uvar.Nseg;
  sensFactInv = 5/2 * rho * TdataSeg^(-1/2);

  sensFact = 1 ./ sensFactInv;

  return;

endfunction
