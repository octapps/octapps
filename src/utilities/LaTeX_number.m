function ret = LaTeX_number ( val, precision = 3, form = "auto", dollar="$" )
  %% LaTeX-format a scalar number, using format 'form', and precision
  %% 'precision' P governs the number of digits to output
  %%
  %% 'form' can be either:
  %%     "f": floating-point format '$%.Pf$' with precision 'P'
  %%     "g": floating-point format '$%.Pg$' where 'P' is the number of significant digits
  %%     "e": for exponential LaTeX notation, with 'P' significant digits
  %%   "auto: for automatic switching between "g" and "e" depending on 'val',
  %%          namely "g" for val in [1e-3, 1e3], or "e" otherwise
  %%
  %% Note: if given a vector/matrix of 'N' elements, returns a cell-array
  %% of 'N' strings with the same size as 'val'

  N = numel ( val );

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

  fmt_f = sprintf ("%s%%.%df%s", dollar, precision, dollar );
  fmt_g = sprintf ("%s%%.%dg%s", dollar, precision, dollar );
  fmt_e = sprintf ("%s%%.%df{\\times}10^{%%d}%s", dollar, precision, dollar );
  fmt_pe0 = sprintf ("%s10^{%%d}%s", dollar, dollar );
  fmt_me0 = sprintf ("%s-10^{%%d}%s", dollar, dollar );

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
        if this_val == 0
          ret{i} = sprintf(fmt_g, 0);
        else
          expon = floor ( log10 ( abs(this_val) ) );
          mant = this_val / 10^expon;
          if ( abs(mant) - 1 < 10^(-precision) )	%% don't print redundant '1x10^x', but rather '10^x'
            if mant < 0
              ret{i} = sprintf(fmt_me0, expon );
            else
              ret{i} = sprintf(fmt_pe0, expon );
            endif
          else
            ret{i} = sprintf(fmt_e, mant, expon );
          endif
        endif
      otherwise
        error ("Something went wrong, form_index = %d undefined ... \n", form_index );
    endswitch

  endfor ## i = 1:N

  %% reshape ret to be same size as val
  ret = reshape(ret, size(val));

endfunction
