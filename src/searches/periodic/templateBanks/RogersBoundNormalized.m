
function ret = RogersBoundNormalized ( n )
  ## Rogers' upper bound on (normalized) packing density in n dimensions

  ## a few 'exact' numbers taken from Conway&Sloane Table 1.2:
  rogersLow24 = [ 0.5, 	0.28868, 0.18470, 0.13127, 0.09987, 0.08112, 0.06981, 0.06326, 0.06007, 0.05953,	\
		 0.06136, 0.06559, 0.07253, 0.08278, 0.09735, 0.11774, 0.14624, 0.18629, 0.24308, 0.32454, 	\
		 0.44289, 0.61722, 0.87767, 1.27241 ];
  ret = [];

  for ni = n

    if ( ni < 0 )
      error ("Only positive dimensions are allowed in RogersBoundNormalized()!\n");
    endif
    
    if ( ni == 0 )
      ret = [ ret, 1 ];
    elseif ( ni <= 24 )
      thisret = rogersLow24 ( ni );
      ret = [ret, thisret ];
    else
    ## approximate expression due to Leech [Eq.(40) in Conway&Sloane ] for (large?) n:
      log2ret = (ni/2) .* log2 ( ni / (4*e*pi) ) + (3/2) * log2(ni) - log2(e/sqrt(pi)) + 5.25 ./ (ni + 2.5);
      thisret = 2 .^ log2ret;
      ret = [ ret, thisret ];
    endif

  endfor

endfunction
