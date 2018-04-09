## Copyright (C) 2016 Christoph Dreissigacker
## Copyright (C) 2016 Reinhard Prix
## Copyright (C) 2011 Karl Wette
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
## @deftypefn {Function File} {@var{pDET} =} DetectionProbabilityStackSlide ( @var{opt}, @var{val}, @dots{} )
##
## Estimate detection probability for given fixed sensitivity-depth signal @var{Depth} = sqrt(S)/h0
##
## @heading where Options are
##
## @table @code
## @item Nseg
## number of StackSlide segments
##
## @item Tdata
## total amount of data used, in seconds
## (Note: @var{Tdata} = Nsft * Tsft, where 'Nsft' is the total number of
## SFTs of length 'Tsft' used in the search, from all @var{detectors})
##
## @item misHist
## mismatch histogram, produced using @command{Hist()}
##
## @item pFA
## false-alarm probability (-ies) *per template* (can be a vector)
##
## @item avg2Fth
## ALTERNATIVE to @var{pFA}: specify average-2F threshold directly (can be a vector)
##
## @item detectors
## CSV list of @var{detectors} to use ("H1"=Hanford, "L1"=Livingston, "V1"=Virgo, @var{...})
##
## @item alpha
## source right ascension in radians (default: all-sky = [0, 2pi])
##
## @item delta
## source declination (default: all-sky = [-pi/2, pi/2])
##
## @item Depth
## fixed sensitivity-depth of signal population (can be a vector)
##
## @item detweights
## detector weights on S_h to use (default: uniform weights)
##
## @end table
##
## @end deftypefn

function pDET = DetectionProbabilityStackSlide ( varargin )

  ## parse options
  uvar = parseOptions ( varargin,
                        {"Nseg", "integer,strictpos,scalar", 1 },
                        {"Tdata", "real,strictpos,scalar" },
                        {"misHist", "a:Hist" },
                        {"pFA", "real,strictpos,vector", []},
                        {"avg2Fth", "real,strictpos,vector", []},
                        {"detectors", "char", "H1,L1" },
                        {"alpha", "real,vector", [0, 2*pi]},
                        {"delta", "real,vector", [-pi/2, pi/2]},
                        {"Depth", "real,strictpos,vector", [] },
                        {"detweights", "real,strictpos,vector", []},
                        []);

  dof = 4;
  ## check input
  assert ( ! ( isempty ( uvar.pFA ) && isempty ( uvar.avg2Fth )), "Need at least one of 'pFA' or 'avg2Fth' to determine false-alarm probability!\n");
  assert ( isempty ( uvar.pFA ) || isempty ( uvar.avg2Fth ), "Must specify exactly one of 'pFA' or 'avg2Fth' to determine false-alarm probability!\n");

  ## compute geometric factor 'R' histogram
  Rsqr = SqrSNRGeometricFactorHist ( "detectors", uvar.detectors, "detweights", uvar.detweights, "alpha", uvar.alpha, "sdelta", sin(uvar.delta) );

  ## get values and weights of R^2 as row vectors

  ## get probability densities and bin quantities
  Rsqr_px = histProbs ( Rsqr );
  [Rsqr_x, Rsqr_dx] = histBins ( Rsqr, 1, "centre", "width" );

  ## get probabilitiy densities for mismatch
  mism_px = histProbs(uvar.misHist);
  [mism_x, mism_dx] = histBins(uvar.misHist, 1, "centre", "width");

  ## check histogram bins are positive and contain no infinities
  assert ( min ( histRange(Rsqr) ) >= 0, "%s: R^2 histogram bins must be positive", funcName );
  assert ( (Rsqr_px(1) == 0) && (Rsqr_px(end) == 0), "%s: R^2 histogram contains non-zero probability in infinite bins", funcName );

  ## chop off infinite bins
  Rsqr_px = Rsqr_px ( 2:end-1 );
  Rsqr_x  = Rsqr_x ( 2:end-1 );
  Rsqr_dx = Rsqr_dx ( 2:end-1 );

  ## compute weights
  Rsqr_w = Rsqr_px .* Rsqr_dx;

  Rsqr_x = Rsqr_x(:)';
  Rsqr_w = Rsqr_w(:)';

  ## chop off infinite bins and resize to column vectors
  mism_px = reshape(mism_px(2:end-1),  [],1);
  mism_x = reshape(mism_x(2:end-1),  [],1);
  mism_dx = reshape(mism_dx(2:end-1), [],1);
  mism_w = mism_px .* mism_dx;

  ## get detection threshold
  if ( !isempty ( uvar.pFA ) )
    sum2Fth = invFalseAlarm_chi2 ( uvar.pFA, uvar.Nseg * dof );
  else
    sum2Fth = uvar.Nseg * uvar.avg2Fth;
  endif

  [ERR, sum2Fth, Depth ] = common_size ( sum2Fth, uvar.Depth );
  assert ( ERR == 0, "%s: Common size failed for size(sum2Fth) = %d x %d, size(Depth) = %d x %d\n", funcName, size(sum2Fth), size(uvar.Depth) );

  ## translate sensitivity depth into per-segment rms SNR 'rhosqr' = sqrt( < rhoCoh^2> )
  rhoSCsqr = 4/25 * uvar.Tdata ./ Depth.^2;

  ## indices for duplicating rows or columns
  ii = ones(length(mism_x),1);
  jj = ones(length(Rsqr_x),1);

  ## rho is computed for each pd and Ns (dim. 1) by summing
  ## false dismissal probability for fixed Rsqr_x, weighted
  ## by Rsqr_w (dim. 2)
  Rsqr_x = Rsqr_x( ii,:);
  Rsqr_w = Rsqr_w( ii,:);
  mism_x = mism_x( :,jj);
  mism_w = mism_w( :,jj);

  pDET = zeros ( size ( Depth ) );
  for i = 1 : length ( pDET(:) )
    pDET(i) = 1 - sum(sum( ChiSquare_cdf ( sum2Fth(i), uvar.Nseg * dof, rhoSCsqr(i) .* Rsqr_x(ii,:) .* (1 - mism_x(:,jj))) .* Rsqr_w(ii,:) .*mism_w(:,jj) ,1),2);
  endfor

  return;

endfunction

%!test
%! Nseg = 90;
%! Tseg = 60 * 3600;
%! Tdata = 12080 * 1800;
%! avg2Fth = 6.109;
%! sum2Fth = Nseg * avg2Fth;
%! pFA = falseAlarm_chi2 ( sum2Fth, 4 * Nseg );
%! misHistSC = createDeltaHist ( 0.7 );
%! pDET = [0.95; 0.9; 0.85];
%! Depths  = SensitivityDepthStackSlide ( "Nseg", Nseg, "Tdata", Tdata, "misHist", misHistSC, "pFD", 1-pDET, "pFA", pFA, "detectors", "H1,L1" );
%! detProbs = DetectionProbabilityStackSlide ( "Nseg", Nseg, "Tdata", Tdata, "misHist", misHistSC, "pFA", pFA, "detectors", "H1,L1", "Depth", Depths );
%! assert ( max ( abs ( detProbs - pDET ) ) < 0.01 );

%!test
%! Nseg = 90;
%! Tseg = 60 * 3600;
%! Tdata = 12080 * 1800;
%! avg2Fth = 6.109;
%! sum2Fth = Nseg * avg2Fth;
%! pFA = falseAlarm_chi2 ( sum2Fth, 4 * Nseg );
%! misHistSC = createGaussianHist ( 0.7,0.1);
%! pDET = [0.95; 0.9; 0.85];
%! Depths  = SensitivityDepthStackSlide ( "Nseg", Nseg, "Tdata", Tdata, "misHist", misHistSC, "pFD", 1-pDET, "pFA", pFA, "detectors", "H1,L1" );
%! detProbs = DetectionProbabilityStackSlide ( "Nseg", Nseg, "Tdata", Tdata, "misHist", misHistSC, "pFA", pFA, "detectors", "H1,L1", "Depth", Depths );
%! assert ( max ( abs ( detProbs - pDET ) ) < 0.01 );
