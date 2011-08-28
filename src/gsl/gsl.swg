// -*- mode: c++; -*-

//
//  Copyright (C) 2010 Karl Wette
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with with program; see the file COPYING. If not, write to the
//  Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
//  MA  02111-1307  USA
//

// Common code for Octave bindings to GSL

// C++ headers
%header %{
  #include <iostream>
  #include <string>
%}

// GSL headers
%header %{
  namespace gsl {
    #include <gsl/gsl_vector.h>
    #include <gsl/gsl_matrix.h>
  }
%}

// No default constructors for classes
%nodefaultctor;

// SWIG exception handling
%include "exception.i"
%header %{
  class gsl_exception {
  public:
    const char *const msg;
    gsl_exception(const char *const msg0) : msg(msg0) {};
  };
%}
%exception {
  try {
    $action
  }
  catch (gsl_exception e) {
    SWIG_exception(SWIG_RuntimeError, e.msg);
  }
}

// Conversions for gsl_matrix
%typemap(in,numinputs=0) gsl::gsl_matrix* *OUTPUT (gsl::gsl_matrix *temp) {
  temp = 0;
  $1 = &temp;
}
%typemap(out) gsl::gsl_matrix* {
  if ($1 == 0) {
    SWIG_fail;
  }    
  const int $1_n = $1->size1;
  const int $1_m = $1->size2;
  Matrix $1_mat($1_n, $1_m);
  for (int $1_i = 0; $1_i < $1_n; ++$1_i) {
    for (int $1_j = 0; $1_j < $1_m; ++$1_j) {
      $1_mat($1_i, $1_j) = gsl::gsl_matrix_get($1, $1_i, $1_j);
    }
  }
  $result = octave_value($1_mat);
  gsl::gsl_matrix_free($1);
}
