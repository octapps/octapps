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
## @deftypefn {Function File} {} PlotAndLabelContour ( @var{C}, @var{ctropt}, @var{ctropt}, @dots{} )
## @deftypefnx{Function File} {} PlotAndLabelContour ( @var{S}, @var{ctropt}, @var{ctropt}, @dots{} )
## @deftypefnx{Function File} {@var{S} =} PlotAndLabelContour ( @dots{} )
##
## Plot contours, possibly with labels
##
## @heading Arguments
##
## @table @var
## @item C
## contour array returned by contourc, etc.
##
## @item S
## @var{S} = contourc2struct(@var{C})
##
## @item ctropt
## @{@var{lev}, @var{prop}, @var{options}@dots{}@}, where:
## @table @var
## @item lev
## contour level(s)
## @item prop
## contour line properties
## @item options
## @table @code
## @item lbl
## label this contour (true/false)
## @item lblpos
## relative position of label along contour
## @item lbldim
## size of area to clear for contour label
## @item lblminlen
## don't label contours shorter than this
## @end table
##
## @end table
##
## @end table
##
## @end deftypefn

function varargout = PlotAndLabelContours(S, varargin)

  ## parse options
  ctropt = struct;
  for j = 1:length(varargin)
    ctropt(j) = parseOptions(varargin{j},
                             {"lev", "numeric,vector"},
                             {"levprop", "cell"},
                             {"lbl", "logical,scalar", false},
                             {"lblpos", "numeric,scalar", 0.5},
                             {"lblsize", "char", "\\scriptsize"},
                             {"lblfmt", "char", "%0.2f"},
                             {"lbldim", "numeric,vector", [0,0]},
                             {"lblminlen", "numeric,scalar", 0});
    assert(ctropt(j).lbldim >= 0);
  endfor

  ## convert contour array to struct, if needed
  if !isstruct(S)
    S = contourc2struct(S);
  endif

  ## range of contours
  Dx = max([S.x]) - min([S.x]);
  Dy = max([S.y]) - min([S.y]);

  ## loop over contours
  hold on;
  for i = 1:length(S)

    ## find first matching contour options
    jj = find(!cellfun(@isempty, arrayfun(@(x) find(x.lev == S(i).lev), ctropt, "UniformOutput", false)));
    if isempty(jj)
      continue
    endif
    j = jj(end);

    ## enclose label code in one-time loop,
    ## so that we can skip over it using 'break'
    do
      if !ctropt(j).lbl
        break
      endif

      ## label region dimensions
      hdx = 0.5 * ctropt(j).lbldim(1) * Dx;
      hdy = 0.5 * ctropt(j).lbldim(2) * Dy;

      ## skip contour label if label dimensions are nonzero
      if hdx == 0 && hdy > 0
        break;
      endif

      ## find length of contour
      dist = cumsum(sqrt(diff(S(i).x).^2 + diff(S(i).y).^2));
      S(i).len = dist(end) / sqrt(Dx^2 + Dy^2);
      dist = [0 dist/dist(end)];

      ## skip contour label if not long enough
      if S(i).len < ctropt(j).lblminlen
        break;
      endif

      ## find midpoint of contour
      xm = interp1(dist, S(i).x, ctropt(j).lblpos);
      ym = interp1(dist, S(i).y, ctropt(j).lblpos);

      ## label region corners
      plbl = cell(2,2);
      plbl{1,1} = [xm-hdx;ym-hdy];
      plbl{1,2} = [xm-hdx;ym+hdy];
      plbl{2,1} = [xm+hdx;ym-hdy];
      plbl{2,2} = [xm+hdx;ym+hdy];

      ## loop over segments of contour
      np = [S(i).x(1);S(i).y(1)];
      for k = 1:length(S(i).x)-1

        ## segment points
        p1 = [S(i).x(k  );S(i).y(k  )];
        p2 = [S(i).x(k+1);S(i).y(k+1)];

        ## check which points are within label region
        p1in = all(plbl{1,1} <= p1) & all(p1 <= plbl{2,2});
        p2in = all(plbl{1,1} <= p2) & all(p2 <= plbl{2,2});

        ## skip contour segments wholly within label
        if p1in && p2in
          continue
        endif

        ## check if contour segment intersects label region
        u = ulbl = zeros(1,4);
        [u(1),ulbl(1)] = TwoLineIntersection(p1, p2, plbl{1,1}, plbl{1,2});
        [u(2),ulbl(2)] = TwoLineIntersection(p1, p2, plbl{1,1}, plbl{2,1});
        [u(3),ulbl(3)] = TwoLineIntersection(p1, p2, plbl{2,2}, plbl{1,2});
        [u(4),ulbl(4)] = TwoLineIntersection(p1, p2, plbl{2,2}, plbl{2,1});
        k = find(0 <= u & u <= 1 & 0 <= ulbl & ulbl <= 1);
        assert(length(k) <= 2);

        ## if two intersections, split segment
        if length(k) == 2
          um = min(u(k));
          uM = max(u(k));
          np = [np, p1 + um.*(p2-p1), nan(2,1), p1 + uM*(p2-p1), p2];
          continue
        endif

        ## if one intersection, truncate segment
        if length(k) == 1
          assert(xor(p1in, p2in));
          u = u(k);
          if p2in
            np = [np, p1 + u.*(p2-p1), nan(2,1)];
          else
            np = [np, p1 + u.*(p2-p1)];
          endif
          continue
        endif

        ## otherwise, add endpoint
        np = [np, p2];

      endfor

      ## recreate contour x and y coordinates
      S(i).x = np(1,:);
      S(i).y = np(2,:);

      ## create label at contour midpoint
      text(xm, ym, strcat(ctropt(j).lblsize,
                          sprintf(ctropt(j).lblfmt, S(i).lev)),
           "horizontalalignment", "center",
           "verticalalignment", "middle");

    until true

    ## plot contour
    S(i).h = plot(S(i).x, S(i).y, ctropt(j).levprop{:});

  endfor

  ## return contour structure
  if nargout > 0
    varargout = {S};
  endif

endfunction

%!test
%!  fig = figure("visible", "off");
%!  [X, Y] = ndgrid(-10:10, -10:10);
%!  Z = X.^2 - Y.^2;
%!  lbllev = 10:10:90;
%!  C = contourc(Z, lbllev);
%!  PlotAndLabelContours(C, {"lev", lbllev, "levprop", {"color", "black"}, "lbl", true, "lbldim", [0.1, 0.1], "lblfmt", "%0.0f"});
%!  close(fig);
