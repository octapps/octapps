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

%include "typemaps.i"   // SWIG typemaps
%header %{
#  ifdef DEBUG
#    include <iostream>
#    include <typeinfo>
#  endif
#  include <octave/oct.h>
#  include <octave/ov.h>
  // import GSL symbols in wrap:: namespace to
  // prevent naming conflicts with wrapped symbols
  namespace wrap {
#    include <gsl/gsl_vector.h>
  }
%}

// This class provides a base class for wrapping a gsl struct.
// It is used to bind GSL gsl_*_alloc / gsl_*_free functions
// to C++ constructor / destructors, which are then wrapped 
// correctly by SWIG/Octave so there are no memory leaks.
%header %{
  template<class T>
    class GSLStruct {
  public:
    T *const ptr;
  private:
    void (*const free)(T*);
  protected:
    GSLStruct(T *ptr0, void (*free0)(T*)) :
      ptr(ptr0), free(free0)
    {
#ifdef DEBUG
      std::cout << "gsl created a " << typeid(T).name() << std::endl;
#endif
    }
    ~GSLStruct() {
      if (free)
	(*free)(ptr);
#ifdef DEBUG
      std::cout << "gsl destroyed a " << typeid(T).name() << std::endl;
#endif
    }
  };
%}

// These are typemaps for converting GSL/C types to native Octave types.
// More will be added as needed.

// Wraps a gsl_vector which is designated as output.
// The wrapping function receives a null pointer and
// should assign it to a new gsl_vector, which is then
// coverted to an Octave column vector on output.
%typemap(in,numinputs=0) wrap::gsl_vector* *OUTPUT (wrap::gsl_vector *temp) {
  temp = 0;
  $1 = &temp;
}
%typemap(argout) wrap::gsl_vector* *OUTPUT {
  if (*$1 == 0) {
    SWIG_fail;
  }    
  const int $1_n = (*$1)->size;
  ColumnVector $1_cv($1_n);
  for (int $1_i = 0; $1_i < $1_n; ++$1_i) {
    $1_cv($1_i) = wrap::gsl_vector_get(*$1, $1_i);
  }
  $result = SWIG_Octave_AppendOutput($result, octave_value($1_cv));
  wrap::gsl_vector_free(*$1);
}
