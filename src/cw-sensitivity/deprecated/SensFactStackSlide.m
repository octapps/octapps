
function sensDepth = SensFactStackSlide ( varargin )
  %% DEPRECATED name: use 'SensitivityDepthStackSlide()' instead!

  warning ("DEPRECATED name: use 'SensitivityDepthStackSlide()' instead of 'SensFactStackSlide()'!\n");
  sensDepth = SensitivityDepthStackSlide ( varargin{:} );
  return;

endfunction
