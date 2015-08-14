function varargin = struct2varargin ( in_struct )
  %% varagin = struct2varagin ( in_struct )
  assert ( isstruct ( in_struct ) );

  names = fieldnames ( in_struct );
  vals  = struct2cell ( in_struct );

  varargin = [ names'; vals' ];
  return;
endfunction
