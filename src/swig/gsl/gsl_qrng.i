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

// Octave bindings to the GSL quasi-random number generator

%module gsl_qrng
%include "gslcommon.swg"
%header %{
  namespace wrap {   // see gslcommon.swg
#    include <gsl/gsl_qrng.h>
  }
%}

// struct gsl_qrng_type
class gsl_qrng_type;
%header %{
  class gsl_qrng_type : public GSLStruct<const wrap::gsl_qrng_type> {
  public:
    gsl_qrng_type(const wrap::gsl_qrng_type* T) :
      GSLStruct<const wrap::gsl_qrng_type>(T, 0)
    {
    }
  };
%}

// different quasi-random number generators
%inline %{
  const gsl_qrng_type gsl_qrng_niederreiter_2 = gsl_qrng_type(wrap::gsl_qrng_niederreiter_2);
  const gsl_qrng_type gsl_qrng_sobol          = gsl_qrng_type(wrap::gsl_qrng_sobol);
  const gsl_qrng_type gsl_qrng_halton         = gsl_qrng_type(wrap::gsl_qrng_halton);
  const gsl_qrng_type gsl_qrng_reversehalton  = gsl_qrng_type(wrap::gsl_qrng_reversehalton);
%}

// struct gsl_qrng
class gsl_qrng {
public:
  gsl_qrng(const gsl_qrng_type*, int);
  ~gsl_qrng();
};
%header %{
  class gsl_qrng : public GSLStruct<wrap::gsl_qrng> {
  public:
    gsl_qrng(const gsl_qrng_type* type, int d) :
      GSLStruct<wrap::gsl_qrng>(wrap::gsl_qrng_alloc(type->ptr, d),
				wrap::gsl_qrng_free)
    {
    }
    // this ctor isn't exported, it's only
    // needed internally by gsl_qrng_clone
    gsl_qrng(wrap::gsl_qrng* q) :
      GSLStruct<wrap::gsl_qrng>(q, wrap::gsl_qrng_free)
    {
    }
  };
%}

// function gsl_qrng_init
%inline %{
  void gsl_qrng_init(gsl_qrng* q) {
    wrap::gsl_qrng_init(q->ptr);
  }
%}

// function gsl_qrng_get
// (last two arguments become Octave output arguments)
void gsl_qrng_get(gsl_qrng*, wrap::gsl_vector* *OUTPUT, int *OUTPUT);
%header %{
  void gsl_qrng_get(gsl_qrng* q, wrap::gsl_vector* *v, int *retn) {
    *v = wrap::gsl_vector_alloc(q->ptr->dimension);
    *retn = wrap::gsl_qrng_get(q->ptr, (*v)->data);
  }
%}

// function gsl_qrng_name
%inline %{
  const char* gsl_qrng_name(const gsl_qrng* q) {
    return wrap::gsl_qrng_name(q->ptr);
  }
%}

// function gsl_qrng_clone
%newobject gsl_qrng_clone;   // allocates a new gsl_qrng
%inline %{
  gsl_qrng* gsl_qrng_clone(const gsl_qrng* q) {
    return new gsl_qrng(wrap::gsl_qrng_clone(q->ptr));
  }
%}
