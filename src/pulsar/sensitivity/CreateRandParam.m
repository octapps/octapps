%% Parses random parameters specs, which may be either
%%   <constant>,     denoting a single value, or
%%   [<min>, <max>], denoting a range of values
%% Syntax:
%%   rng = CreateQandParam(p, p, ...)
%% where
%%   rng = random parameter generator
%%   p   = random parameter spec
function rng = CreateRandParam(varargin)

  %% load quasi-random number generator
  gsl_qrng;
  global cvar;

  %% initial indexes of random and constant parameters
  rng.rii = rng.rm = rng.rc = rng.cii = rng.cc = [];

  %% iterate over parameters
  for i = 1:nargin
    p = varargin{i};
    switch numel(p)
      case 1    % <constant>
	rng.cii(end+1,1) = i;
	rng.cc(end+1,1) = p;
      case 2    % [<min>, <max>]
	rng.rii(end+1,1) = i;
	rng.rm(end+1,1) = max(p) - min(p);
	rng.rc(end+1,1) = min(p);
      otherwise
	error("Invalid random parameter spec!");
    endswitch
  endfor

  %% create quasi-random number generator if needed
  if length(rng.rii) > 0
    rng.q = new_gsl_qrng(cvar.gsl_qrng_halton, length(rng.rii));
  endif
  rng.allconst = (length(rng.rii) == 0);

endfunction
