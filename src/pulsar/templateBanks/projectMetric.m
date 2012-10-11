function gOut_ij = projectMetric ( g_ij, c=1 )
  %% gOut_ij = projectMetric ( g_ij, c=1 )
  %%
  %% project out metric dimension 'c' from the input n x n metric 'g_ij',
  %% by projecting onto the subspace orthogonal to the coordinate-axis of 'c', namely
  %% gOut_ij = g_ij - ( g_ic * g_jc / g_cc )
  %%
  %% Returns a 'projected' n x n metric, where the projected-out dimension 'c' is replaced
  %% by zeros, consistent with the behavior of XLALProjectMetric()

  assert ( issymmetric ( g_ij ), "Input metric 'g_ij' must be a symmetric square matrix" );

  n = columns ( g_ij );

  gOut_ij = zeros ( n, n );

  for i = 1:n
    for j = 1:n
      if ( i == c || j == c )
        gOut_ij(i, j) = 0;	%% exact result to avoid roundoff issues
      else
        gOut_ij( i, j ) = g_ij( i, j ) - g_ij(c, i) * g_ij ( c, j ) / g_ij ( c, c );
      endif
    endfor
  endfor

  return;

endfunction