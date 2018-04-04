// -*- mode: c; -*-

//
// Copyright (C) 2010 Karl Wette
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with with program; see the file COPYING. If not, write to the
// Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
// MA  02111-1307  USA
//

// Octave bindings to miscalleous GSL functions
%module gsl;
%include "exception.i"
%feature("autodoc");
#if OCTAVE_VERSION_HEX >= 0x030800 && SWIG_VERSION < 0x020012
#error Requires SWIG version 2.0.12 or greater
#elif SWIG_VERSION < 0x020011
#error Requires SWIG version 2.0.11 or greater
#endif

// Include headers
%header %{
#include <stdio.h>
#include <string.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_matrix.h>
#include <gsl/gsl_qrng.h>
#include <gsl/gsl_sf_gamma.h>
%}

// Typemaps for gsl_matrix
%typemap(in) gsl_matrix* {
  Matrix $1_mat = $input.matrix_value();
  const size_t $1_n = $1_mat.rows();
  const size_t $1_m = $1_mat.cols();
  if ($1_n <= 0 || $1_m <= 0) {
    SWIG_exception(SWIG_RuntimeError, "Argument $argnum must be a double matrix");
  }
  $1 = gsl_matrix_alloc($1_n, $1_m);
  for (size_t $1_i = 0; $1_i < $1_n; ++$1_i) {
    for (size_t $1_j = 0; $1_j < $1_m; ++$1_j) {
      gsl_matrix_set($1, $1_i, $1_j, $1_mat($1_i, $1_j));
    }
  }
}
%typemap(out) gsl_matrix* {
  if ($1 == 0) {
    SWIG_exception(SWIG_RuntimeError, "Argument $1 is NULL");
  }
  const size_t $1_n = $1->size1;
  const size_t $1_m = $1->size2;
  Matrix $1_mat($1_n, $1_m);
  for (size_t $1_i = 0; $1_i < $1_n; ++$1_i) {
    for (size_t $1_j = 0; $1_j < $1_m; ++$1_j) {
      $1_mat($1_i, $1_j) = gsl_matrix_get($1, $1_i, $1_j);
    }
  }
  $result = octave_value($1_mat);
}
%typemap(freearg) gsl_matrix* {
  gsl_matrix_free($1);
}
%typemap(newfree) gsl_matrix* {
  gsl_matrix_free($1);
}

// GSL quasi-random number generator
typedef struct {
  %extend {
    gsl_qrng(const gsl_qrng* qrng) {
      return gsl_qrng_clone(qrng);
    }
    gsl_qrng(const char* type, size_t dim) {
      if (strcmp(type, "niederreiter_2") == 0) {
        return gsl_qrng_alloc(gsl_qrng_niederreiter_2, dim);
      }
      else if (strcmp(type, "sobol") == 0) {
        return gsl_qrng_alloc(gsl_qrng_sobol, dim);
      }
      else if (strcmp(type, "halton") == 0) {
        return gsl_qrng_alloc(gsl_qrng_halton, dim);
      }
      else if (strcmp(type, "reversehalton") == 0) {
        return gsl_qrng_alloc(gsl_qrng_reversehalton, dim);
      }
      else {
        printf("new_gsl_qrng: invalid generator type '%s', must be one of "
               "'niederreiter_2', "
               "'sobol', "
               "'halton', "
               "'reversehalton'\n",
               type);
        return NULL;
      }
    }
    void reset() {
      gsl_qrng_init($self);
    }
    %newobject get;
    gsl_matrix* get(size_t n = 1) {
      gsl_matrix *m = gsl_matrix_alloc($self->dimension, n);
      gsl_vector *v = gsl_vector_alloc($self->dimension);
      for (size_t i = 0; i < n; ++i) {
        if (gsl_qrng_get($self, v->data) != 0) {
          gsl_matrix_free(m);
          gsl_vector_free(v);
          return 0;
        }
        gsl_vector_view vv = gsl_matrix_column(m, i);
        gsl_vector_memcpy(&vv.vector, v);
      }
      gsl_vector_free(v);
      return m;
    }
    ~gsl_qrng() {
      gsl_qrng_free($self);
    }
  }
} gsl_qrng;

// Gamma functions
%define gsl_sf_gamma_function(NAME)
%inline %{
  gsl_matrix* gsl_sf_gamma_##NAME(gsl_matrix* a, gsl_matrix* x) {
    if (a->size1 != x->size1) {
      printf("gsl_sf_gamma"#NAME": rows of a and x do not agree");
      return NULL;
    }
    if (a->size2 != x->size2) {
      printf("gsl_sf_gamma"#NAME": cols of a and x do not agree");
      return NULL;
    }
    gsl_matrix* res = gsl_matrix_alloc(a->size1, a->size2);
    for (size_t i = 0; i < a->size1; ++i) {
      for (size_t j = 0; j < a->size2; ++j) {
        gsl_matrix_set(res, i, j,
                       gsl_sf_gamma_##NAME(
                                           gsl_matrix_get(a, i, j),
                                           gsl_matrix_get(x, i, j)
                                           )
                       );
      }
    }
    return res;
  }
%}
%enddef
gsl_sf_gamma_function(inc);
gsl_sf_gamma_function(inc_P);
gsl_sf_gamma_function(inc_Q);

// Tests
%header %{
/*
%!test
%!  gsl;
%!test
%!  gsl;
%!  q = new_gsl_qrng ("halton", 3);
%!  assert(gsl_qrng_get(q), [0.50000; 0.33333; 0.20000], 1e-3);
%!test
%!  gsl;
%!  assert(gsl_sf_gamma_inc(4.5, 0), gamma(4.5), 1e-3);
%!  assert(gsl_sf_gamma_inc(4.5, 2.2), 10.273, 1e-3);
%!  assert(gsl_sf_gamma_inc_P(4.5, 2.2), 0.11683, 1e-3);
%!  assert(gsl_sf_gamma_inc_Q(4.5, 2.2), 1 - 0.11683, 1e-3);

*/
%}
