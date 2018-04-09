## Copyright (C) 2010 Karl Wette
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
## @deftypefn {Function File} {} plotHist ( @var{hgrm}, @var{options}, @dots{}, @var{hgrm}, @var{options}, @dots{} )
## @deftypefnx{Function File} {@var{hh} =} plotHist ( @dots{} )
##
## Plot a histogram as a stair graph
##
## @heading Arguments
##
## @table @var
## @item hgrm
## histogram object
##
## @item options
## @var{options} to pass to graphics function
##
## @item hh
## return graphics handles
##
## @end table
##
## @heading @command{plotHist()}-specific options
##
## @table @code
## @item stairs
## if true [default], plot histogram as a stair-stepped
## graph; otherwise, plot a smooth line through bin centres
##
## @item infbins
## if true [default], plot stalks for counts in infinite bins
## @end table
##
## @end deftypefn

function varargout = plotHist(varargin)

  ## get positions of histograms
  jj = find(cellfun(@(H) isa(H, "Hist"), varargin));
  if isempty(jj)
    error("%s: at least one argument must be a histogram", funcName);
  endif
  jj = [jj, length(varargin)+1];

  ## return handles
  if nargout == 1
    varargout{1} = zeros(1,length(jj)-1);
  endif

  ## loop over histograms
  for j = 1:length(jj)-1

    ## get histogram and associated options
    hgrm = varargin{jj(j)};
    dim = histDim(hgrm);
    opts = varargin(jj(j)+1:jj(j+1)-1);
    plotopts = {};
    if mod(length(opts), 2) == 1
      assert(ischar(opts{1}), "%s: first option to histogram #%i must be a string", funcName, j);
      plotopts{end+1} = opts{1};
      opts = opts(2:end);
    endif

    ## parse options, removing unknown options for plot()
    stairs = true;
    infbins = true;
    for i = 1:2:length(opts)
      switch opts{i}
        case "stairs"
          assert(islogical(opts{i+1}), "%s: argument is 'stairs' is not a logical value", funcName);
          stairs = opts{i+1};
        case "infbins"
          assert(islogical(opts{i+1}), "%s: argument is 'infbins' is not a logical value", funcName);
          infbins = opts{i+1};
        otherwise
          plotopts(end+1:end+2) = opts(i:i+1);
      endswitch
    endfor

    ## get histogram probability densities
    p = histProbs(hgrm);

    ## select plot based on dimension
    switch dim

      case 1

        ## if histogram is empty
        if sum(p(:)) == 0

          ## plot a stem point at zero
          h = plot([0, 0], [0, 1], plotopts{:}, 0, 1, plotopts{:});
          set(h(2), "color", get(h(1), "color"), "marker", "o");

        else

          ## get histogram bins
          [xl, xh] = histBins(hgrm, 1, "lower", "upper");

          ## find maximum range of non-zero probabilities
          ii = find(p > 0);
          min_ii = min(ii);
          max_ii = max(ii);
          if min_ii == length(p)
            --min_ii;
          endif
          if max_ii == 1;
            ++max_ii;
          endif
          ii = min_ii:max_ii;
          xl = reshape(xl(ii), 1, []);
          xh = reshape(xh(ii), 1, []);
          p = reshape(p(ii), 1, []);

          if stairs

            ## create staircase, possibly with stems for infinite values
            x = reshape([xl(1), xh; xl, xh(end)], 1, []);
            y = reshape([0, p; p, 0], 1, []);
            if isinf(xl(1))
              x(x == -inf) = xl(2);
            endif
            if isinf(xh(end))
              x(x == +inf) = xh(end-1);
            endif

          else

            ## create straight line, possibly with stems for infinite values
            x = [xl(1), 0.5*(xl+xh), xh(end)];
            y = [0, p, 0];
            if isinf(xl(1))
              x = [xl(2)*[1,1,1], x(2:end)];
              y = [0, p(1), 0, y(2:end)];
            endif
            if isinf(xh(end))
              x = [x(1:end-1), xh(end-1)*[1,1,1]];
              y = [y(1:end-1), 0, p(end), 0];
            endif

          endif

          ## plot histogram and possibly stems, delete lines which are not needed
          h = plot(x, y, plotopts{:}, x(2), y(2), plotopts{:}, x(end-1), y(end-1), plotopts{:});
          if infbins && isinf(xl(1))
            set(h(2), "color", get(h(1), "color"), "marker", "o");
          else
            delete(h(2));
            h(2) = NaN;
          endif
          if infbins && isinf(xh(end))
            set(h(3), "color", get(h(1), "color"), "marker", "o");
          else
            delete(h(3));
            h(3) = NaN;
          endif
          h(isnan(h)) = [];

        endif

      case 2

        ## if histogram is empty
        if sum(p(:)) == 0

          ## plot a circular point at zero
          h = plot(0, 0, plotopts{:});
          set(h, "marker", "o");

        else

          ## get histogram bins
          xc = histBinGrids(hgrm, 1, "centre");
          yc = histBinGrids(hgrm, 2, "centre");

          ## plot contours
          h = contour(xc, yc, p, plotopts{:});

        endif

      otherwise
        error("%s: cannot plot %iD histograms", funcName, dim);

    endswitch

    ## return handles
    if nargout == 1
      varargout{1}(j) = h(1);
    endif

    ## save hold state, then hold on
    if j == 1
      hold_state = ishold();
    endif
    hold on;

  endfor

  ## restore hold state
  if hold_state != ishold()
    hold;
  endif

endfunction

%!test
%!  fig = figure("visible", "off");
%!  hgrm = createGaussianHist(1.2, 3.4, "binsize", 0.1);
%!  plotHist(hgrm, "k-");
%!  plotHist(hgrm, "k-", "stairs", true);
%!  plotHist(hgrm, "k-", "stairs", false);
%!  close(fig);
