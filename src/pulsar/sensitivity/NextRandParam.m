%% Generates values for random parameters, given a generator
%% Syntax:
%%   [v, v, ...] = NextRandParam(rng, N)
%% where
%%   rng = random parameter generator
%%   N   = number of values to generate
%%   v   = values of random parameter
function varargout = NextRandParam(rng, N)

  %% load quasi-random number generator
  gsl_qrng;
  global cvar;

  %% check input arguments
  if nargout ~= length(rng.rii) + length(rng.cii);
    error("Incorrect number of output arguments!");
  endif

  %% fill random parameters with next quasi-random vector
  if length(rng.rii) > 0
    r = gsl_qrng_get(rng.q, N);
    [varargout{rng.rii}] = deal(mat2cell(rng.rm(:,ones(N,1)) .* r + ...
					 rng.rc(:,ones(N,1)),ones(length(rng.rii),1),N){:});
  endif

  %% fill constant parameters
  if length(rng.cii) > 0
    [varargout{rng.cii}] = deal(mat2cell(rng.cc(:,ones(N,1)),ones(length(rng.cii),1),N){:});
  endif

endfunction
