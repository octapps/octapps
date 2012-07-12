function sensFact = SensFactHoughF ( varargin )
  %% estimate 'Hough-on-Fstat' sensitivity factor
  %% input arguments:
  %% 'Nseg':    	number of StackSlide segments
  %% 'Tdata':   	total amount of data used, in seconds
  %% 'misHist': 	mismatch histogram, produced using addDataToHist()
  %% 'pFD':     	false-dismissal probability = 1 - pDet
  %% 'pFA':     	false-alarm probability (-ies) *per template* [can be a vector]
  %% 'detectors': 	string containing detector-network to use 'H'=Hanford, 'L'=Livingston, 'V'=Virgo
  %% 'Fth': 	F-stat threshold (on F, not 2F!) in each segment for 'pixel' selection

  %% ----- parse commandline
  uvar = parseOptions ( varargin,
                       {'Nseg', 'scalar', 1 },		%% number of StackSlide segments
                       {'Tdata', 'scalar' },  		%% total amount of data used, in seconds
                       {'misHist', 'Hist' },		%% mismatch histogram, produced using addDataToHist()
                       {'pFD', 'scalar', 0.1},		%% false-dismissal probability = 1 - pDet
                       {'pFA', 'vector'},		%% false-alarm probability (-ies) per template
                       {'detectors', 'char', "HL" },	%% string containing detector-network to use 'H'=Hanford, 'L'=Livingston, 'V'=Virgo
                       {'Fth', 'scalar', 5.2 / 2 }	%% F-stat threshold (on F, not 2F!) in each segment for 'pixel' selection
                       );

  Rsqr = SqrSNRGeometricFactorHist ( "detectors", uvar.detectors, "mism_hgrm", uvar.misHist );
  rho = SensitivitySNR ( uvar.pFD, uvar.Nseg, Rsqr, "HoughFstat", "paNt", uvar.pFA, "Fth", uvar.Fth);

  TdataSeg = uvar.Tdata / uvar.Nseg;
  sensFactInv = 5/2 * rho * TdataSeg^(-1/2);

  sensFact = 1 ./ sensFactInv;

  return;

endfunction
