function Fveto = computeFveto ( inFstats )
  %% Fveto = computeFveto ( inFstats )
  %% compute "F+veto" stat from input vector with columns [2F, 2F_1, 2F_2, ...]
  %% vetoed candidates are set to Fveto=-1, otherwise Fveto>=0
  %%
  %% F+veto is defined as F+veto = { 2F  if 2F > max(2F_1, 2F_2,...); -1 otherwise }

  [ numDraws, numRows ] = size ( inFstats );
  numDet = numRows - 1;

  twoF = inFstats(:,1);
  twoFmax = max ( inFstats(:, 2:end)' )';

  veto = find ( twoF < twoFmax );

  Fveto = twoF;
  Fveto(veto) = -1;	%% allow to remove those completely from stats

  return;

endfunction
