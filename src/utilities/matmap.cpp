#include <string>
#include <list>

#include <octave/oct.h>
#include <octave/parse.h>
#include <octave/mx-defs.h>
#include <octave/dMatrix.h>
#include <octave/fMatrix.h>
#include <octave/CMatrix.h>
#include <octave/fCMatrix.h>
 
// convert from octave_value
template<class C> C FromValue(const octave_value&);
template<> ArrayN<double> FromValue(const octave_value& a) {
  return a.array_value();
}
template<> ArrayN<float> FromValue(const octave_value& a) {
  return a.float_array_value();
}
template<> ArrayN<Complex> FromValue(const octave_value& a) {
  return a.complex_array_value();
}
template<> ArrayN<FloatComplex> FromValue(const octave_value& a) {
  return a.float_complex_array_value();
}
template<> Array2<double> FromValue(const octave_value& a) {
  return a.matrix_value();
}
template<> Array2<float> FromValue(const octave_value& a) {
  return a.float_matrix_value();
}
template<> Array2<Complex> FromValue(const octave_value& a) {
  return a.complex_matrix_value();
}
template<> Array2<FloatComplex> FromValue(const octave_value& a) {
  return a.float_complex_matrix_value();
}

// convert to octave_value
template<class C> octave_value ToValue(const C&);
template<> octave_value ToValue(const Array2<double>& a) {
  return octave_value((Matrix)a);
}
template<> octave_value ToValue(const Array2<float>& a) {
  return octave_value((FloatMatrix)a);
}
template<> octave_value ToValue(const Array2<Complex>& a) {
  return octave_value((ComplexMatrix)a);
}
template<> octave_value ToValue(const Array2<FloatComplex>& a) {
  return octave_value((FloatComplexMatrix)a);
}

// mapping function for a function handle / string name
template<class F, class C, class A, class B>
class MapFunction {
private:
  F f;
public:
  MapFunction(F f0) : f(f0) {}
  ArrayN<C> operator()(const ArrayN<A>& a, const ArrayN<B>& b) const {
    octave_value_list args;
    args.append(octave_value(a));
    args.append(octave_value(b));
    octave_value_list retn = feval(f, args);
    if (retn.length() != 1) {
      error("matmap: function must return only 1 argument!");
      return ArrayN<C>();
    }
    return FromValue<ArrayN<C> >(retn(0));
  }
};

// mapping functions for matrix multiplication
template<class C> class MapMatrixMultiply;
template<>
class MapMatrixMultiply<FloatComplex> {
public:
  FloatComplexMatrix operator()(const FloatComplexMatrix& a, const FloatComplexMatrix& b) const {
    return xgemm(false, false, a, false, false, b);
  }
};
template<>
class MapMatrixMultiply<Complex> {
public:
  ComplexMatrix operator()(const ComplexMatrix& a, const ComplexMatrix& b) const {
    return xgemm(false, false, a, false, false, b);
  }
};
template<>
class MapMatrixMultiply<float> {
public:
  FloatMatrix operator()(const FloatMatrix& a, const FloatMatrix& b) const {
    return xgemm(false, a, false, b);
  }
};
template<>
class MapMatrixMultiply<double> {
public:
  Matrix operator()(const Matrix& a, const Matrix& b) const {
    return xgemm(false, a, false, b);
  }
};

// templated worker function
template<class C, class T, class A, class B>
ArrayN<C> do_matmap_2(const T& func, const ArrayN<A>& arrA, const ArrayN<B>& arrB) {

  // length of the 3rd dimension
  const int n = arrA.dims()(2);

  // create an index vector to extract matrices in the first 2 dimensions 
  Array<idx_vector> idx(3);
  idx(0) = idx_vector::colon;
  idx(1) = idx_vector::colon;
  idx(2) = idx_vector(0);

  // extract the matrices
  Array2<A> matA = FromValue<Array2<A> >(octave_value(arrA.index(idx)));
  Array2<B> matB = FromValue<Array2<B> >(octave_value(arrB.index(idx)));

  Array2<C> matC = func(matA, matB);

  return FromValue<ArrayN<C> >(ToValue(matC));

}

// templated worker function
template<class C, class A, class B>
octave_value do_matmap_1(const octave_value_list& args) {

  // extract the arrays
  ArrayN<A> arrA = FromValue<ArrayN<A> >(args(1));
  ArrayN<B> arrB = FromValue<ArrayN<B> >(args(2));

  // first argument must be function handle/name or operator
  if (args(0).is_function_handle() || args(0).is_inline_function()) {
    return octave_value(do_matmap_2<C>(MapFunction<octave_function*,C,A,B>(args(0).function_value()), arrA, arrB));
  }
  else if (args(0).is_string()) {
    const std::string s = args(0).string_value();
    if (s.compare("*") == 0) {
      return octave_value(do_matmap_2<C>(MapMatrixMultiply<C>(), arrA, arrB));
    }
    else {
      return octave_value(do_matmap_2<C>(MapFunction<std::string,C,A,B>(s), arrA, arrB));
    }
  }
  else {
    error("matmap: argument #1 must be function handle/name or operator!");
    return octave_value();
  }

}

// help string
const char helpstr[] = "\
 Computes the matrices C(:,:,n) = f(A(:,:,n), B(:,:,n))\n\
 Syntax:\n\
   C = matmap(f, A, B)\n\
 where:\n\
   A, B = 3-D arrays (3rd dimensions must agree)\n\
   f    = @function or \"function name\"\n\
        = \"*\" for matrix multiplication\n\
   C    = 3-D result array\n\
";

// octave function
DEFUN_DLD (matmap, args, nargout, helpstr) {
  
  // check input and output arguments
  if (args.length() != 3) {
    error("matmap: requires 3 input arguments!");
    return octave_value();
  }
  if (nargout > 1) {
    error("matmap: requires 1 output argument!");
    return octave_value();
  }

  // 2nd and 3rd arguments must be arrays
  if (!args(1).is_matrix_type() || !args(1).is_matrix_type()) {
    error("matmap: arguments #2 and #3 must be arrays!");
    return octave_value();
  }
  if (args(1).ndims() < 3 || args(2).ndims() < 3) {
    error("matmap: arguments #2 and #3 must be 3-D arrays!");
    return octave_value();
  }
  if (args(1).size()(2) != args(2).size()(2)) {
    error("matmap: argumsnts #2 and #3 must have the same 3rd dimension size!");
    return octave_value();
  }

  // all permutations of single/double, real/complex
  if (args(1).is_single_type() && args(1).is_complex_type()) {
    if (args(2).is_single_type() && args(1).is_complex_type())
      return do_matmap_1<FloatComplex, FloatComplex, FloatComplex>(args);
    else if (args(2).is_single_type())
      return do_matmap_1<FloatComplex, FloatComplex, float>(args);
    else if (args(2).is_complex_type())
      return do_matmap_1<Complex, FloatComplex, Complex>(args);
    else
      return do_matmap_1<Complex, FloatComplex, double>(args);
  }
  else if (args(1).is_single_type()) {
    if (args(2).is_single_type() && args(1).is_complex_type())
      return do_matmap_1<FloatComplex, float, FloatComplex>(args);
    else if (args(2).is_single_type())
      return do_matmap_1<float, float, float>(args);
    else if (args(2).is_complex_type())
      return do_matmap_1<Complex, float, Complex>(args);
    else
      return do_matmap_1<double, float, double>(args);
  }
  else if (args(1).is_complex_type()) {
    if (args(2).is_single_type() && args(1).is_complex_type())
      return do_matmap_1<Complex, Complex, FloatComplex>(args);
    else if (args(2).is_single_type())
      return do_matmap_1<Complex, Complex, float>(args);
    else if (args(2).is_complex_type())
      return do_matmap_1<Complex, Complex, Complex>(args);
    else
      return do_matmap_1<Complex, Complex, double>(args);
  }
  else {
    if (args(2).is_single_type() && args(1).is_complex_type())
      return do_matmap_1<Complex, double, FloatComplex>(args);
    else if (args(2).is_single_type())
      return do_matmap_1<double, double, float>(args);
    else if (args(2).is_complex_type())
      return do_matmap_1<Complex, double, Complex>(args);
    else
      return do_matmap_1<double, double, double>(args);
  }

}
