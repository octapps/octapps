## Copyright (C) 2006 Reinhard Prix
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
## @deftypefn {Function File} {@var{ret} =} randSignalParams ( @var{ranges}, [ @var{numSignals} ] )
##
## generate random-parameters for 'numSignals' (default=1, returns a colunm-vector)
## signals within given ranges and return the signal-parameters in a struct
## sigparams = [h0, cosi, psi, phi0, alpha, delta, f, f1dot, f2dot, f3dot]
##
## @end deftypefn

function ret = randSignalParams(ranges, numSignals)
  ## generate corresponding random-values

  if ( !exist("numSignals") )
    numSignals = 1;
  endif

  ## handle Doppler-params as optional, but always output them!! (3 spindowns)
  if ( ! isfield ( ranges, "Freq") )
    ranges.Freq = 0;
  endif
  if ( ! isfield ( ranges, "Alpha") )
    ranges.Alpha = 0;
  endif
  if ( ! isfield ( ranges, "Delta" ) )
    ranges.Delta = 0;
  endif
  if ( ! isfield ( ranges, "f1dot" ) )
    ranges.f1dot = 0;
  endif
  if ( ! isfield ( ranges, "f2dot" ) )
    ranges.f2dot = 0;
  endif
  if ( ! isfield ( ranges, "f3dot" ) )
    ranges.f3dot = 0;
  endif

  ret.Freq  = pickFromRange ( ranges.Freq, numSignals );
  ret.Alpha = pickFromRange ( ranges.Alpha, numSignals );

  cthMin = cos( pi/2 - min(ranges.Delta(:) ));
  cthMax = cos( pi/2 - max(ranges.Delta(:) ));
  ret.Delta = pi/2 - acos ( pickFromRange([cthMin,cthMax], numSignals ) );

  ret.h0    = pickFromRange ( ranges.h0, numSignals );
  ret.cosi  = pickFromRange ( ranges.cosi, numSignals );
  ret.psi   = pickFromRange ( ranges.psi, numSignals );
  ret.phi0  = pickFromRange ( ranges.phi0, numSignals );

  ret.f1dot = pickFromRange ( ranges.f1dot, numSignals );
  ret.f2dot = pickFromRange ( ranges.f2dot, numSignals );
  ret.f3dot = pickFromRange ( ranges.f3dot, numSignals );

  ## return also Aplus, Across
  ## ret.aPlus = 0.5 * ret.h0 * ( 1.0 + ret.cosi ^ 2);
  ## ret.aCross = ret.h0 * ret.cosi;

endfunction ## randSignalParams()

%!assert(isstruct(randSignalParams(struct("h0", 1e-24, "cosi", 0, "psi", pi/4, "phi0", pi/5))))
