function [sig, degs, mins, secs] = rad_to_dms ( rads )
  %% [sig, degs, mins, secs] = rad_to_dms ( rads )
  %%
  %% convert radians 'rads' into degrees "<sig>degs:minutes:secs", where <sig> is either +1 or -1

  sig = sign ( rads );

  degDecimal = abs(rads) * (180 / pi );

  degs = fix ( degDecimal );

  remdr1 = degDecimal - degs;
  mins = fix ( remdr1 * 60 );

  remdr2 = remdr1 - mins / 60;
  secs = remdr2 * 3600;

  return;

endfunction

%!test
%! rads = dms_to_rad ( "10:11:12.345" );
%! [sig, dd,mm,ss] = rad_to_dms ( rads );
%! assert ( sig, 1 ); assert ( dd, 10 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );
%!

%!test
%! rads = dms_to_rad ( "-10:11:12.345" );
%! [sig, dd,mm,ss] = rad_to_dms ( rads );
%! assert (sig, -1 ); assert ( dd, 10 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );

%!test
%! rads = dms_to_rad ( "-0:11:12.345" );
%! [sig, dd,mm,ss] = rad_to_dms ( rads );
%! assert ( sig, -1 ); assert ( dd, 0 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e5*eps );
