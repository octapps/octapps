function [fkdot_epoch1, fkdotband_epoch1] = ExtrapolatePulsarSpinRange ( epoch0, epoch1, fkdot_epoch0, fkdotband_epoch0, numSpins )
 %% [fkdot_epoch1, fkdotband_epoch1] = ExtrapolatePulsarSpinRange ( epoch0, epoch1, fkdot_epoch0, fkdotband_epoch0, numSpins )
 %% function to translate spin-values \f$\f^{(l)}\f$ and bands from epoch0 to epoch1
 %% based on LALSuite programs/functions HierarchSearchGCT and LALExtrapolatePulsarSpinRange
 %% NOTE: different index conventions between lalapps and octave - (k) here corresponds to [k-1] in LALExtrapolatePulsarSpinRange,
 %%       i.e. fkdot(1)=fkdot[0]=freq, fkdot(2)=fkdot(1)=f1dot, ...

 dtau = epoch1 - epoch0;

 for l = 0:1:numSpins

  flmin     = 0;
  flmax     = 0;
  kfact     = 1; # values for k=0
  dtau_powk = 1; # values for k=0

  for k = 0:1:numSpins-l

   fkltauk0 = fkdot_epoch0(k+l+1) * dtau_powk;
   fkltauk1 = fkltauk0 + fkdotband_epoch0(k+l+1) * dtau_powk;
   fkltauk_min = min ( fkltauk0, fkltauk1 );
   fkltauk_max = max ( fkltauk0, fkltauk1 );
   flmin += fkltauk_min / kfact;
   flmax += fkltauk_max / kfact;
   kfact *= (k+1);
   dtau_powk *= dtau;

  endfor # k = 0:1:numSpins-l

  fkdot_epoch1(l+1)     = flmin;
  fkdotband_epoch1(l+1) = flmax - flmin;

 endfor # l = 0:1:numSpins

endfunction # ExtrapolatePulsarSpinRange()
