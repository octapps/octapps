## Copyright (C) 2011, 2013 Karl Wette
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
## @deftypefn {Function File} {@var{hgrmt} =} addHists ( @var{addop}, @var{hgrms}@dots{} )
##
## Add multiple histograms together.
##
## @heading Arguments
##
## @table @var
## @item addop
## operation used to add histograms:
## @table @code
## @item count
## sum histogram counts
##
## @item prob
## sum histogram probabilities
## @end table
##
## @item hgrms
## histograms to add; @code{[]} arguments are ignored
##
## @item hgrmt
## total histogram
##
## @end table
##
## @end deftypefn

function hgrmt = addHists(addop, varargin)

  ## check input
  assert(ischar(addop));
  hgrms = {};
  dim = [];
  for i = 1:length(varargin)
    hgrm = varargin{i};
    if !isempty(hgrm)
      assert(isHist(hgrm), "Argument #%i must be either a valid histogram object, or []", i);
      if isempty(dim)
        dim = length(hgrm.bins);
      else
        assert(dim == length(hgrm.bins), "Histograms must have the same dimensionality");
      endif
      hgrms{end+1} = hgrm;
    endif
  endfor

  ## if no histogram arguments, return []; if only one histogram argument, return it
  if length(hgrms) == 0
    hgrmt = [];
    return;
  elseif length(hgrms) == 1
    hgrmt = hgrms{1};
    return;
  endif

  ## get union of all histogram bins in each dimension
  ubins = histBinUnions(hgrms{:});

  ## resample histograms to union of all histogram bins
  for i = 1:length(hgrms)
    hgrms{i} = resampleHist(hgrms{i}, ubins{:});
  endfor

  ## use 1st histogram, with zeroed count, as total histogram
  hgrmt = hgrms{1};
  hgrmt.counts = zeros(size(hgrmt.counts));

  ## add histograms
  switch addop

    case "count"   ## add histogram counts
      for i = 1:length(hgrms)
        hgrmt.counts += hgrms{i}.counts;
      endfor

    case "prob"   ## ad histogram probabilities
      for i = 1:length(hgrms)
        hgrmt.counts += histProbs(hgrms{i});
      endfor

    otherwise
      error("%s: unknown addition operation '%s'", funcName, addop);

  endswitch

endfunction

%!test
%!  hgrm1 = addDataToHist(Hist(1, 0:12), 0.5 + (0:11)');
%!  hgrm2 = addDataToHist(Hist(1, 0:3:12), 0.5 + (0:11)');
%!  hgrmt = addHists("count", hgrm1, hgrm2);
%!  p = histProbs(hgrmt);
%!  assert(length(p) == 14 && p(2:end-1) == 1/12);

%!test
%!  hgrms = arrayfun(@(x) addDataToHist(Hist(1, 0:12), 0.5 + x), 0:11, "UniformOutput", false);
%!  hgrmt = addHists("count", hgrms{:});
%!  p = histProbs(hgrmt);
%!  assert(length(p) == 14 && p(2:end-1) == 1/12);
