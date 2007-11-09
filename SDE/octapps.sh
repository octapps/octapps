#!/bin/sh
# sets octapps and octave environment variables
# IF input parameter
#   SET top directory from input
# ENDIF
# IF top directory is defined
#   SET path to SDE sub-directory
# ENDIF
if [ $# -gt 0 ]; then
  export OCTAVE_TOP=${1}
  export OCTAVE_TOP=`echo "$OCTAVE_TOP" | sed 's/\/$//' `
fi
if [ ${#OCTAPPS_TOP} -gt 0 ]; then
  export OCTAPPS_SDE=${OCTAPPS_TOP}/SDE
fi
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
#  -- Define Octave path = Octave path
# ENDIF
if [ ${#OCTAPPS_SDE} -gt 0 ]; then
  if [ ${#OCTAVE_PATH} -gt 0 ]; then
    export OCTAVE_PATH=${OCTAPPS_SDE}\:${OCTAVE_PATH}
  else
    export OCTAVE_PATH=${OCTAPPS_SDE}
  fi

  for i in `cat ${OCTAPPS_SDE}/octave_paths.txt`
    do
      export OCTAVE_PATH=${OCTAPPS_TOP}/$i\:${OCTAVE_PATH}
    done
#
fi
