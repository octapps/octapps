#!/bin/csh
# sets octapps and octave environment variables
# IF input parameter
#   SET top directory from input
# ENDIF
# IF top directory is defined
#   SET path to SDE sub-directory
# ENDIF
if ($#argv>0) then
  setenv OCTAPPS_TOP $1
  setenv OCTAPPS_TOP `echo "$OCTAPPS_TOP" | sed 's/\/$//' `
endif
if $?OCTAPPS_TOP then
  setenv OCTAPPS_SDE ${OCTAPPS_TOP}/SDE
endif
# IF SDE sub-directory defined
#   IF OCTAVE path already defined
#       ADD SDE sub-directory to path
#   ELSE
#       SET OCTAVE path to SDE sub-directory
#   ENDIF
#   LOOP over directories in octapps path list
#       ADD directory to OCTAVE path
#   ENDLOOP
#
# ENDIF
if $?OCTAPPS_SDE then
  if $?OCTAVEPATH then
    setenv OCTAVEPATH ${OCTAPPS_SDE}\:${OCTAVEPATH}
  else
    setenv OCTAVEPATH ${OCTAPPS_SDE}
  endif
  foreach i(`cat ${OCTAPPS_SDE}/octapps_paths.txt`)
    setenv OCTAVEPATH ${OCTAPPS_TOP}/{$i}\:${OCTAVEPATH}
  end
#
endif
