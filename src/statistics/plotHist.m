%% Plot histograms.
%% Syntax:
%%   plotHist(hgrm, colour)
%%   plotHist([rows cols], hgrm, colour, hgrm, colour, ...)
%%   plotHist(..., 'PROP', val, ..., hgrm, colour, 'prop', val, ...)
%%   h = plotHist(...)
%% where:
%%   hgrm   = histogram struct
%%   colour = a colour specification:
%%               either a cell array
%%                  {col, ...}, where col = [R G B] or 'string'
%%               or a string with one-letter colours
%%                  "c..."
%%            number of colours may be either 1 or 2:
%%               1 colour:  plots an outline of the histogram
%%               2 colours: plots a filled area in colour 1,
%%                               and an outline in colour 2
%%   rows,  = for multiple histogram, number of rows /columns
%%   cols        in the sub-plot matrix
%%   'PROP' = property which applies to all histograms
%%               (it must appear before all histograms in the input)
%%   'prop' = property applied to the previous histogram only
%%   h      = returns graphics handles

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

function varargout = plotHist(varargin)

  %% check input
  if nargin == 0
    error("Need some input arguments!");
  endif

  %% check for subplot rows/columns in first argument
  i = 1;
  if ismatrix(varargin{1}) && numel(varargin{1}) == 2
    rows = varargin{i}(1);
    cols = varargin{i}(2);
    ++i;
  else
    rows = cols = 1;
  endif
  index = 0;

  %% check for global properties before first histogram
  allprops = [];
  while nargin-i+1 >= 2 && ischar(varargin{i})
    allprops = [allprops, i, i + 1];
    i += 2;
  endwhile

  %% while arguments remain
  while nargin-i+1 > 0

    %% need at least two more arguments
    if nargin-i+1 < 2
      error("Missing arguments: expected a histogram-colour pair!");
    endif

    %% next argument should be a histogram
    hgrm  = varargin{i};
    if !isHist(hgrm)
      error("Input argument #%i must be a histogram struct!", i);
    endif
    ++i;

    %% next arguments should be a colour spec (string or cell)
    colour = varargin{i};
    if !(ischar(colour) || iscell(colour)) || length(colour) > 2
      error("Input argument #%i must be a string or cell (length <= 2)!", i);
    endif
    ++i;
    if ischar(colour)
      strcolour = colour;
      colour = {};
      for j = 1:length(strcolour)
	colour{j} = strcolour(j);
      endfor
    endif

    %% check for additional property values
    props = allprops;
    while nargin-i+1 >= 2 && ischar(varargin{i})
      props = [props, i, i + 1];
      i += 2;
    endwhile

    %% advance subplot index
    ++index;
    if index > rows*cols
      error("Insufficient number of sub-plots given in argument #1!");
    endif
    subplot(rows, cols, index);

    %% x-y outline of histogram
    x = hgrm.xb{1}(reshape([1:length(hgrm.xb{1}); 1:length(hgrm.xb{1})], 1, []));
    y = [0, hgrm.px(reshape([1:length(hgrm.px); 1:length(hgrm.px)], 1, []))', 0];

    if length(colour) == 1

      %% if given one colour, plot an outline
      hh{index}(1) = plot(x, y, colour{1}, varargin{props});

    else

      %% if given two colours, plot a filled region
      hh{index}(1) = patch(x, y, colour{1}, varargin{props});

      %% if second colour is different, plot a separate outline
      if colour{2} != colour{1}
	set(gca, "nextplot", "add");
	hh{index}(2) = plot(x, y, colour{2}, varargin{props});
	set(gca, "nextplot", "replace");
      endif

    endif

  endwhile

  %% return handles
  if nargout == 1
    varargout = {hh};
  endif

endfunction
