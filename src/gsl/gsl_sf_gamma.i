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

// Octave module wrapping some GSL gamma functions

%module gsl_sf_gamma

%include "gsl.swg"

%header %{
  namespace gsl {
    #include <gsl/gsl_sf_gamma.h>
  }
%}

%inline %{
  Matrix gsl_sf_gamma_inc(Matrix& a, Matrix& x) {
    if (a.rows() != x.rows())
      throw gsl_exception("gsl_sf_gamma_inc: rows of a and x do not agree");
    if (a.cols() != x.cols())
      throw gsl_exception("gsl_sf_gamma_inc: cols of a and x do not agree");
    Matrix res = Matrix(a.rows(), a.cols());
    for (int i = 0; i < a.rows(); ++i) {
      for (int j = 0; j < a.cols(); ++j) {
        res(i,j) = gsl::gsl_sf_gamma_inc(a(i,j), x(i,j));
      }
    }
    return res;
  }
%}

%inline %{
  Matrix gsl_sf_gamma_inc_Q(Matrix& a, Matrix& x) {
    if (a.rows() != x.rows())
      throw gsl_exception("gsl_sf_gamma_inc_Q: rows of a and x do not agree");
    if (a.cols() != x.cols())
      throw gsl_exception("gsl_sf_gamma_inc_Q: cols of a and x do not agree");
    Matrix res = Matrix(a.rows(), a.cols());
    for (int i = 0; i < a.rows(); ++i) {
      for (int j = 0; j < a.cols(); ++j) {
        res(i,j) = gsl::gsl_sf_gamma_inc_Q(a(i,j), x(i,j));
      }
    }
    return res;
  }
%}

%inline %{
  Matrix gsl_sf_gamma_inc_P(Matrix& a, Matrix& x) {
    if (a.rows() != x.rows())
      throw gsl_exception("gsl_sf_gamma_inc_P: rows of a and x do not agree");
    if (a.cols() != x.cols())
      throw gsl_exception("gsl_sf_gamma_inc_P: cols of a and x do not agree");
    Matrix res = Matrix(a.rows(), a.cols());
    for (int i = 0; i < a.rows(); ++i) {
      for (int j = 0; j < a.cols(); ++j) {
        res(i,j) = gsl::gsl_sf_gamma_inc_P(a(i,j), x(i,j));
      }
    }
    return res;
  }
%}
