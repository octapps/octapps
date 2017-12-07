%% Copyright (C) 2017 Reinhard Prix
%%
%% This program is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by
%% the Free Software Foundation; either version 2 of the License, or
%% (at your option) any later version.
%%
%% This program is distributed in the hope that it will be useful,
%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%% GNU General Public License for more details.
%%
%% You should have received a copy of the GNU General Public License
%% along with with program; see the file COPYING. If not, write to the
%% Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%% MA  02111-1307  USA

%% p = max2F_pdf_empirical ( maxTwoF, Ntrials, hgrm_pdf )
%%
%% Compute probability density for maximum 2F (coherent or semi-coherent) out of Ntrials
%% independent draws, for given 2F noise distribution (pdf) histogram 'hgrm'.
%% Can take vector-arguments for maxTwoF.
%%

function p = max2F_pdf_empirical ( maxTwoF, Ntrials, hgrm )
  assert ( isscalar ( Ntrials ) );
  assert ( isa(hgrm, "Hist"));
  assert ( histDim(hgrm) == 1 );

  Nout = length(maxTwoF);
  p = zeros ( size ( maxTwoF ) );

  ## get probability densities
  prob = histProbs ( hgrm, "finite" );
  ## get bins boundaries
  [xl, xh] = histBins(hgrm, 1, "finite", "lower", "upper");

  for i = 1 : Nout

    x_i = maxTwoF(i);

    cdf_i = cumulativeDistOfHist ( hgrm, x_i );

    if ( x_i <= xl(1) || xh(end) <= x_i );
      pdf_i = 0;
    else
      ii = find ( xl <= x_i & x_i < xh );
      assert(isscalar(ii));
      pdf_i = prob(ii);
    endif

    logp = log(Ntrials) + log(pdf_i) +  (Ntrials-1) * log(cdf_i);

    p(i) = e.^logp;
  endfor

  return;

endfunction

%!test
%! Ntrials = 1e3;
%! twoF = linspace ( 10, 40, 100 );
%! pdf0 = max2F_pdf ( twoF, Ntrials );
%!
%! hgrm = Hist ( 1, {"lin", "dbin", 0.05, "bin0", 0 } );
%! F = @(x) chi2pdf(x, 4);
%! hgrm = initHistFromFunc(hgrm, F, [0, 50] );
%! pdf1 = max2F_pdf_empirical ( twoF, Ntrials, hgrm );
%! relerr = max ( abs ( pdf0 - pdf1 ) ./ pdf0 );
%! assert ( relerr < 2e-2 );
