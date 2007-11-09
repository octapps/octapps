#!/bin/sh
# sets matapps and matlab environment variables
# IF input parameter
#   SET top directory from input
# ENDIF
# IF top directory is defined
#   SET path to SDE sub-directory
# ENDIF
if [ $# -gt 0 ]; then
  export MATAPPS_TOP=${1}
  export MATAPPS_TOP=`echo "$MATAPPS_TOP" | sed 's/\/$//' `
fi
if [ ${#MATAPPS_TOP} -gt 0 ]; then 
  export MATAPPS_SDE=${MATAPPS_TOP}/SDE
fi
# IF SDE sub-directory defined
#   IF MATLAB path already defined
#       ADD SDE sub-directory to path
#   ELSE
#       SET MATLAB path to SDE sub-directory
#   ENDIF
#   LOOP over directories in Matapps path list
#       ADD directory to MATLAB path
#   ENDLOOP
#
#  -- Define Octave path = Matlab path
# ENDIF
if [ ${#MATAPPS_SDE} -gt 0 ]; then
  if [ ${#MATLABPATH} -gt 0 ]; then
    export MATLABPATH=${MATAPPS_SDE}\:${MATLABPATH}
  else
    export MATLABPATH=${MATAPPS_SDE}
  fi 

  for i in `cat ${MATAPPS_SDE}/matapps_paths.txt`
    do
      export MATLABPATH=${MATAPPS_TOP}/$i\:${MATLABPATH}
#clean the matlabpath variable from the back
# do this each step to avoid "Word too long." error
      export MATLABPATH=`${MATAPPS_SDE}/cleanpath.pl MATLABPATH`
    done
#
  export OCTAVE_PATH=${MATLABPATH}
fi
