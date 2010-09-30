// -*- mode: c++; -*-

%include "typemaps.i"
%header %{
#  ifdef DEBUG
#    include <iostream>
#    include <typeinfo>
#  endif
#  include <octave/oct.h>
#  include <octave/ov.h>
  namespace wrap {
#    include <gsl/gsl_vector.h>
  }
%}

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
