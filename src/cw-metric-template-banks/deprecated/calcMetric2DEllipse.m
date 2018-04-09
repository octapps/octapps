## Copyright (C) 2008 Reinhard Prix
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with with program; see the file COPYING. If not, write to the
## Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA  02111-1307  USA

## -*- texinfo -*-
## @deftypefn {Function File} { [ @var{ret}, @var{angle}, @var{smin}, @var{smaj} ] =} calcMetric2DEllipse ( @var{gij}, @var{mismatch}, @var{numPoints}, @var{rotate} )
## @deftypefnx{Function File} {@var{ret} =} calcMetric2DEllipse ( @var{gij}, @var{mismatch}, @var{numPoints} ) :
##
## Given a parameter-space metric 'gij' and a mismatch 'm', return the
## corresponding metric 2D ellipse (centered at (0,0)) using 'numPoints'.
## If 'rotate' is given, rotate ellipse by this angle.
##
## @heading Note
##
## only the first 2 dimensions of gij are used!
##
## @end deftypefn

function [ret, angle, sMin, sMaj] = calcMetric2DEllipse ( gij, mismatch, numPoints, rotate )
  global debug;

  if ( exist("rotate") )
    alpha0 = rotate;
  else
    alpha0 = 0;
  endif

  gaa = gij(1,1);
  gad = gij(1,2);
  gdd = gij(2,2);

  [evs, ll] = eig ( gij(1:2,1:2) );
  ews = [ ll(1,1), ll(2,2) ];

  [ewS,i] = sort ( ews );

  ## Semiminor/major axes from eigenvalues of the metric.
  sMin = sqrt ( mismatch / ewS(2) );
  sMaj = sqrt ( mismatch / ewS(1) );

  ## Angle of semimajor axis (corresponding to *smaller* EV!) with "horizontal" from corresponding eigenvector
  evMaj = evs(:,i(1));
  angle = atan2( evMaj(2), evMaj(1) );

  ## printf ("angle = %g\n", angle );

  if (angle <= - pi/2)
    angle += pi;
  elseif (angle > pi/2)
    angle -= pi;
  endif

  ## printf ("angle1 = %g, alpha0 = %g\n", angle, alpha0 );

  ret = [];
  ## Loop ellipse
  for i=1:numPoints + 1
    c = 2 * pi * i / numPoints ;
    x = sMaj * cos(c);
    y = sMin * sin(c);
    r = sqrt( x*x + y*y );
    b = atan2 ( y, x );
    ## printf ("x = %g, y = %g, b = %g\n", x, y, b );
    ret = [ ret; r * cos( angle + alpha0 + b ), r * sin( angle + alpha0 + b ) ];
  endfor

  return;

endfunction
