// -*- mode: c++; -*-

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

// Octave module wrapping the GSL quasi-random number generator

%module gsl_qrng

%include "gsl.swg"

%header %{
  namespace gsl {
    #include <gsl/gsl_qrng.h>
  }
%}

class gsl_qrng {
public:
  ~gsl_qrng();
};
%header %{
  class gsl_qrng {
  public:
    gsl::gsl_qrng *const p;
    gsl_qrng(gsl::gsl_qrng *const p0) : p(p0) {}
    ~gsl_qrng() {
      gsl::gsl_qrng_free(p);
    }
  };
%}

%inline %{
  enum gsl_qrng_type {
    gsl_qrng_niederreiter_2,
    gsl_qrng_sobol,
    gsl_qrng_halton,
    gsl_qrng_reversehalton
  };
%}

%newobject gsl_qrng_alloc;
%inline %{
  gsl_qrng* gsl_qrng_alloc(const gsl_qrng_type type, unsigned int dim) {
    switch (type) {
    case gsl_qrng_niederreiter_2: return new gsl_qrng(gsl::gsl_qrng_alloc(gsl::gsl_qrng_niederreiter_2, dim));
    case gsl_qrng_sobol:          return new gsl_qrng(gsl::gsl_qrng_alloc(gsl::gsl_qrng_sobol, dim));
    case gsl_qrng_halton:         return new gsl_qrng(gsl::gsl_qrng_alloc(gsl::gsl_qrng_halton, dim));
    case gsl_qrng_reversehalton:  return new gsl_qrng(gsl::gsl_qrng_alloc(gsl::gsl_qrng_reversehalton, dim));
    default:
      throw gsl_exception("gsl_qrng_alloc: invalid gsl_qrng_type");
    }
  }
%}

%newobject gsl_qrng_clone;
%inline %{
  gsl_qrng* gsl_qrng_clone(const gsl_qrng* qrng) {
    return new gsl_qrng(gsl::gsl_qrng_clone(qrng->p));
  }
%}

%inline %{
  void gsl_qrng_init(gsl_qrng* qrng) {
    gsl::gsl_qrng_init(qrng->p);
  }
%}

%inline %{
  gsl::gsl_matrix* gsl_qrng_get(const gsl_qrng* qrng, int n = 1) {
    gsl::gsl_matrix *m = gsl::gsl_matrix_alloc(qrng->p->dimension, n);
    gsl::gsl_vector *v = gsl::gsl_vector_alloc(qrng->p->dimension);
    for (int i = 0; i < n; ++i) {
      if (gsl::gsl_qrng_get(qrng->p, v->data) != 0) {
        gsl::gsl_matrix_free(m);
        gsl::gsl_vector_free(v);
        return 0;
      }
      gsl::gsl_vector_view vv = gsl::gsl_matrix_column(m, i);
      gsl::gsl_vector_memcpy(&vv.vector, v);
    }
    return m;
  }
%}
