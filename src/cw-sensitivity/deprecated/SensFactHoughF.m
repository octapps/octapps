
function sensDepth = SensFactHoughF ( varargin )
  %% DEPRECATED name: use 'SensitivityDepthHoughF()' instead!

  warning ("DEPRECATED name: use 'SensitivityDepthHoughF()' instead of 'SensFactHoughF()'!\n");
  sensDepth = SensitivityDepthHoughF ( varargin{:} );
  return;

endfunction
