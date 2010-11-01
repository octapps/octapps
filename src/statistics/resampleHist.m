%% Resamples a histogram to a new set of bins
%% Syntax:
%%   hgrm = resampleHist(hgrm, k, newbins_k)
%%   hgrm = resampleHist(hgrm, newbins_1, ..., newbins_dim)
%% where:
%%   hgrm      = histogram struct
%%   k         = dimension along which to resample
%%   newbins_k = new bins in dimension k (dim = number of dimensions)

%%
%%  Copyright (C) 2010 Karl Wette
%%
%%  This program is free software; you can redistribute it and/or modify
%%  it under the terms of the GNU General Public License as published by
%%  the Free Software Foundation; either version 2 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU General Public License for more details.
%%
%%  You should have received a copy of the GNU General Public License
%%  along with with program; see the file COPYING. If not, write to the
%%  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%%  MA  02111-1307  USA
%%

function hgrm = resampleHist(hgrm, varargin)

  %% check input
  assert(isHist(hgrm));
  dim = length(hgrm.xb);

  %% if all arguments are not scalars, and
  %% number of arguments equal to number of dimensions,
  %% take each arguments as new bins in k dimensions
  allnotscalar = eval(strcat(sprintf("!isscalar(varargin{%i}) && ", 1:length(varargin)), " 1"));
  if allnotscalar
    if length(varargin) != dim
      error("Number of new bin vectors must match number of dimensions");
    endif
    
    %% loop over dimensions
    for k = 1:dim
      hgrm = resampleHist(hgrm, k, varargin{k});
    endfor

  else

    %% otherwise intepret arguments as [k, nxb]
    if length(varargin) != 2
      error("Invalid input arguments!");
    endif
    [k, nxb] = deal(varargin{:});
    assert(isscalar(k));
    assert(isvector(nxb) && length(nxb) > 1);
    nxb = sort(nxb(:)');
    
    %% get old bin boundaries and probability array
    xb = hgrm.xb{k};
    px = hgrm.px;

    %% if either old bin boundaries or probability array are empty
    if isempty(xb)

      hgrm.xb{k} = nxb;
      siz = size(hgrm.px);
      siz(k) = length(nxb) - 1;
      if dim == 1
	siz(2) = 1;
      endif
      hgrm.px = zeros(siz);

    else
    
      %% round bin boundaries
      [xb, nxb] = roundHistBinBounds(xb, nxb);
      
      %% check that new bins cover the range of old bins
      if !(min(nxb) <= min(xb)) || !(max(nxb) >= max(xb))
	error("Range of new bins (%g to %g) does not include old bins (%g to %g)!",
	      min(nxb), max(nxb), min(xb), max(xb));
      endif
      
      %% permute dimension k to beginning of array,
      %% then flatten other dimensions
      perm = [k 1:(k-1) (k+1):dim];
      px = permute(px, perm);
      siz = size(px);
      px = reshape(px, siz(1), []);
      
      %% if new bins are a superset of old bins, no
      %% resampling is required - just need to extend
      %% probability array with zeros
      nxbss = nxb(min(xb) <= nxb & nxb <= max(xb));
      if length(nxbss) == length(xb) && nxbss  == xb
	nloz = length(nxb(nxb < min(xb)));
	nhiz = length(nxb(nxb > max(xb)));
	npx = [zeros(nloz, size(px, 2));
	       px;
	       zeros(nhiz, size(px, 2))];
      else
	%% otherwise, need to interpolate
	%% probabilities to new bins
	xbl = xb(1:end-1);
	dxb = diff(xb);
	dnxb = diff(nxb);
	
	%% calculate probabilities along dimension k
	Px = px .* dxb(:)(:,ones(size(px, 2), 1));
	
	%% create cumulative probability array resampled over new bins
	Cx = zeros(length(nxb), size(px, 2));
	for i = 1:length(nxb)
	  
	  %% decide what fraction of each old bin
	  %% should contribute to new bin
	  fr = (nxb(i) - xbl) ./ dxb;
	  fr(fr < 0) = 0;
	  fr(fr > 1) = 1;
	  
	  %% assign cumulative probability to new bin
	  Cx(i,:) = sum(Px .* fr(:)(:,ones(size(px, 2), 1)), 1);
	  
	endfor
	
	%% calculate new probability array from cumulative probabilities
	npx = (Cx(2:end,:) - Cx(1:end-1,:)) ./ dnxb(:)(:,ones(size(px, 2), 1));
	
      endif
      
      %% unflatten other dimensions, then
      %% restore original dimension order
      siz(1) = size(npx, 1);
      npx = reshape(npx, siz);
      %% octave-3.2.3 bug : ipermute doesn't work!
      iperm = zeros(size(perm));
      iperm(perm) = 1:length(perm);
      npx = permute(npx, iperm);
      
      %% resampled histogram
      hgrm.xb{k} = nxb;
      hgrm.px = npx;

      endif
      
  endif

endfunction
