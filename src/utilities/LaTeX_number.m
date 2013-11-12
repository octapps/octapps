%% Copyright (C) 2012 Reinhard Prix
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

function ret = LaTeX_number ( val, precision = 3, form = "auto" )
  %% ret = LaTeX_number ( val, precision = 3, form = "auto" )
  %%
  %% LaTeX-format a scalar number, using format 'form', and precision
  %% 'precision' P governs the number of digits to output
  %%
  %% 'form' can be either:
  %%     "f": floating-point format '$%.Pf$' with precision 'P'
  %%     "g": floating-point format '$%.Pg$' where 'P' is the number of significant digits
  %%     "e": for exponential LaTeX notation, with 'P' significant digits
  %%   "auto": for automatic switching between "g" and "e" depending on 'val',
  %%          namely "g" for val in [1e-3, 1e3], or "e" otherwise
  %%
  %% Note: if given a vector/matrix of length 'N' of numbers, returns a cell-arrary
  %% of 'N' strings

  N = length ( val );

  ret = cell(1, N );

  %% avoid repeated string-comparisons in case we're dealing with a long vector of numbers
  FORM_F = 0; FORM_G = 1; FORM_E = 2; FORM_AUTO = 3;
  if     ( strcmp ( form, "f" ) ) form_index = FORM_F;
  elseif ( strcmp ( form, "g" ) ) form_index = FORM_G;
  elseif ( strcmp ( form, "e" ) ) form_index = FORM_E;
  elseif ( strcmp ( form, "auto" ) ) form_index = FORM_AUTO;
  else
    error ("Invalid input 'form'='%s'. Allowed are {'f', 'g', 'e', 'auto'}\n", form );
  endif

  fmt_f = sprintf ("$%%.%df$", precision );
  fmt_g = sprintf ("$%%.%dg$", precision );
  fmt_e = sprintf ("$%%.%df\\times 10^{%%d}$", precision );
  fmt_e0= sprintf ("$10^{%%d}$", precision );

  for i = 1:N

    this_val = val(i);

    if ( form_index == FORM_AUTO )
      if ( ( this_val < 1e-3 ) || ( this_val >= 1e3  ) )
        form_index = FORM_E;
      else
        form_index = FORM_G;
      endif
    endif

    switch ( form_index )
      case FORM_F
        ret{i} = sprintf (fmt_f, this_val );
      case FORM_G
        ret{i} = sprintf (fmt_g, this_val );
      case FORM_E
        expon = floor ( log10 ( this_val ) );
        mant = this_val / 10^expon;
        if ( abs(mant - 1) < 10^(-precision) )	%% don't print redundant '1x10^x', but rather '10^x'
          ret{i} = sprintf(fmt_e0, expon );
        else
          ret{i} = sprintf(fmt_e, mant, expon );
        endif
      otherwise
        error ("Something went wrong, form_index = %d undefined ... \n", form_index );
    endswitch

  endfor ## i = 1:N

  return;

endfunction
