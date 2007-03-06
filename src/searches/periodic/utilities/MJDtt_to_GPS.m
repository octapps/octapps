%% convert MJD (based on TT) into GPS seconds 
%% translated from LAL-function LALTTMJDtoGPS() in BinaryPulsarTiming.c
%%
function GPS = MJDtt_to_GPS ( MJDtt )

  %% Check not before the start of GPS time (MJD 44222)
  if (MJDtt < 44244)
    error ("Input time is not in range [before MJD0 = 44222].\n");
  endif

  %% there is the magical number factor of 32.184 + 19 leap seconds to the start of GPS time
  GPS = (MJDtt - 44244) * 86400 - 51.184;

  return;
endfunction
