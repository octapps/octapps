// -*- mode: c++; -*-

%module gsl_qrng
%include "gslcommon.swg"
%header %{
  namespace wrap {
#    include <gsl/gsl_qrng.h>
  }
%}

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
%inline %{
  const gsl_qrng_type* gsl_qrng_niederreiter_2() {
    static const gsl_qrng_type x(wrap::gsl_qrng_niederreiter_2);
    return &x;
  }
  const gsl_qrng_type* gsl_qrng_sobol() {
    static const gsl_qrng_type x(wrap::gsl_qrng_sobol);
    return &x;
  }
  const gsl_qrng_type* gsl_qrng_halton() {
    static const gsl_qrng_type x(wrap::gsl_qrng_halton);
    return &x;
  }
  const gsl_qrng_type* gsl_qrng_reversehalton() {
    static const gsl_qrng_type x(wrap::gsl_qrng_reversehalton);
    return &x;
  }
%}

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
    gsl_qrng(wrap::gsl_qrng* q) :
      GSLStruct<wrap::gsl_qrng>(q, wrap::gsl_qrng_free)
    {
    }
  };
%}

void gsl_qrng_init(gsl_qrng*);
%header %{
  void gsl_qrng_init(gsl_qrng* q) {
    wrap::gsl_qrng_init(q->ptr);
  }
%}

void gsl_qrng_get(gsl_qrng*, wrap::gsl_vector* *OUTPUT, int *OUTPUT);
%header %{
  void gsl_qrng_get(gsl_qrng* q, wrap::gsl_vector* *v, int *retn) {
    *v = wrap::gsl_vector_alloc(q->ptr->dimension);
    *retn = wrap::gsl_qrng_get(q->ptr, (*v)->data);
  }
%}

%inline %{
  const char* gsl_qrng_name(const gsl_qrng* q) {
    return wrap::gsl_qrng_name(q->ptr);
  }
%}

%newobject gsl_qrng_clone;
%inline %{
  gsl_qrng* gsl_qrng_clone(const gsl_qrng* q) {
    return new gsl_qrng(wrap::gsl_qrng_clone(q->ptr));
  }
%}
