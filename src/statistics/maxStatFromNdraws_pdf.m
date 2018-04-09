## Copyright (C) 2017, 2018 Reinhard Prix
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
## @deftypefn {Function File} {@var{p} =} maxStatFromNdraws_pdf ( @var{x}, @var{Ndraws}, @var{statHgrm} )
##
## Probability density (pdf) for the maximum out of @var{Ndraws} independent draws from an
## arbitrary statistic, defined via its empirical probability density @var{statHgrm} as a histogram object.
##
## Return p(@var{x}): pdf over (vector of) max(Statistic) statistics values @var{x}'
##
## @end deftypefn

function p = maxStatFromNdraws_pdf( x, Ndraws, statHgrm )

  assert ( isscalar ( Ndraws ) );
  assert ( isa(statHgrm, "Hist"));
  assert ( histDim(statHgrm) == 1 );

  p = NaN( size(x) );

  ## deal with special input values +-inf
  ii = isinf(x);
  if any(ii(:))
    p(ii) = 0;
  endif

  ## deal with statistic values outside of empirical histogram
  xRange = histRange ( statHgrm );
  ii = ((x <= min(xRange)) | (x >= max(xRange)) );
  if ( any(ii(:)) )
    p(ii) = 0;
  endif

  ii = !isfinite(p);
  if any(ii(:))

    indsPos = find(ii(:)>0);
    Npts = length( indsPos );

    statisticCDF = zeros ( 1, Npts );
    statisticPDF = zeros ( 1, Npts );

    ## get pdf for given input values
    xc_i  = histBins ( statHgrm, 1, "finite", "centre");
    pdf_i = histProbs( statHgrm,    "finite" );
    statisticPDF = interp1 ( xc_i, pdf_i, x(indsPos) );

    ## get cdf for given input values
    for i = 1 : Npts
      statisticCDF(i) = cumulativeDistOfHist ( statHgrm, x(indsPos(i)) );
    endfor

    ## combine for pdf(maxStat):
    logp = log(Ndraws) + log ( statisticPDF ) +  (Ndraws-1) * log ( statisticCDF );
    p(indsPos) = e.^logp;
  endif

  return;

endfunction

%!test
%! Ndraws = 1e3;
%! twoF = linspace ( 10, 40, 100 );
%! pdf0 = maxChi2FromNdraws_pdf ( twoF, Ndraws, dof=4 );
%!
%! hgrm = Hist ( 1, {"lin", "dbin", 0.05, "bin0", 0 } );
%! F = @(x) chi2pdf(x, 4);
%! hgrm = initHistFromFunc(hgrm, F, [0, 50] );
%! pdf1 = maxStatFromNdraws_pdf ( twoF, Ndraws, hgrm );
%! relerr = max ( abs ( pdf0 - pdf1 ) ./ pdf0 );
%! assert ( relerr < 2e-3 );
