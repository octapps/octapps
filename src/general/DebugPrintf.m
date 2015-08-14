function DebugPrintf ( level, varargin )
  global debugLevel;
  if ( isempty ( debugLevel ) ) debugLevel = 0; endif

  if ( debugLevel >= level )
    fprintf ( stderr, varargin{:} );
  endif
  return;
endfunction %% DebugPrintf()
