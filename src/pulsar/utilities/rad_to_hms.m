function [ hours, mins, secs ] = rad_to_hms ( rads )
  %% [ hours, mins, secs ] = rad_to_hms ( rads )
  %% convert radians into hours:minutes:seconds format

  assert ( rads >= 0, "Only positive angles allowed, got '%f'\n", rads );

  hoursDecimal = rads * (12 / pi );

  hours = fix ( hoursDecimal );

  remdr1 = hoursDecimal - hours;
  mins = fix ( remdr1 * 60 );

  remdr2 = remdr1 - mins / 60;
  secs = remdr2 * 3600;

  return;
endfunction

%!test
%! rads = hms_to_rad ( "10:11:12.345" );
%! [hh, mm, ss] = rad_to_hms ( rads );
%! assert ( hh, 10 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e4*eps );

%!test
%! rads = hms_to_rad ( "0:11:12.345" );
%! [hh, mm, ss] = rad_to_hms ( rads );
%! assert ( hh, 0 ); assert ( mm, 11 ); assert ( ss, 12.345, 1e4*eps );
