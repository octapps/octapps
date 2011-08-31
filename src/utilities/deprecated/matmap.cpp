#include <iostream>
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
const int Trans = 1;
const int Conj  = 2;
template<class C> class MapMatrixMultiply;
template<>
class MapMatrixMultiply<FloatComplex> {
private:
  const int opa, opb;
public:
  MapMatrixMultiply(const int opa0, const int opb0) : opa(opa0), opb(opb0) {}
  FloatComplexMatrix operator()(const FloatComplexMatrix& a, const FloatComplexMatrix& b) const {
    return xgemm(opa & Trans, opa & Conj, a, opb & Trans, opb & Conj, b);
  }
};
template<>
class MapMatrixMultiply<Complex> {
private:
  const int opa, opb;
public:
  MapMatrixMultiply(const int opa0, const int opb0) : opa(opa0), opb(opb0) {}
  ComplexMatrix operator()(const ComplexMatrix& a, const ComplexMatrix& b) const {
    return xgemm(opa & Trans, opa & Conj, a, opb & Trans, opb & Conj, b);
  }
};
template<>
class MapMatrixMultiply<float> {
private:
  const int opa, opb;
public:
  MapMatrixMultiply(const int opa0, const int opb0) : opa(opa0), opb(opb0) {}
  FloatMatrix operator()(const FloatMatrix& a, const FloatMatrix& b) const {
    return xgemm(opa & Trans, a, opb & Trans, b);
  }
};
template<>
class MapMatrixMultiply<double> {
private:
  const int opa, opb;
public:
  MapMatrixMultiply(const int opa0, const int opb0) : opa(opa0), opb(opb0) {}
  Matrix operator()(const Matrix& a, const Matrix& b) const {
    return xgemm(opa & Trans, a, opb & Trans, b);
  }
};

// templated worker function
template<class C, class T, class A, class B>
ArrayN<C> do_matmap_2(const T& func, const ArrayN<A>& arrA, const ArrayN<B>& arrB) {

  // length of the 3rd dimension
  const int nA = arrA.dims()(2);
  const int nB = arrB.dims()(2);
  const int nC = nA > nB ? nA : nB;

  // create an index vector to extract input matrices, which
  // are slices of the arrays in the 1st and 2nd dimensions
  Array<idx_vector> idx(3);
  idx(0) = idx_vector::colon;
  idx(1) = idx_vector::colon;

  // extract first input matrices and compute return matrix
  idx(2) = idx_vector(0);
  Array2<A> matA = FromValue<Array2<A> >(octave_value(arrA.index(idx)));
  Array2<B> matB = FromValue<Array2<B> >(octave_value(arrB.index(idx)));
  Array2<C> matC = func(matA, matB);

  // create an output array of the correct size, and store first return matrix
  ArrayN<C> arrC(dim_vector(matC.dims()(0), matC.dims()(1), nC));
  arrC.assign(idx, matC, C());

  // compute and store the remaining result matrices
  for (int i = 1; i < nC; ++i) {

    // extract the next input matrices, unless they are singletons
    idx(2) = idx_vector(i);
    if (nA != 1)
      matA = FromValue<Array2<A> >(octave_value(arrA.index(idx)));
    if (nB != 1)
      matB = FromValue<Array2<B> >(octave_value(arrB.index(idx)));

    // compute and store return matrix
    matC = func(matA, matB);
    arrC.assign(idx, matC, C());

  }

  // remove any trailing singletons
  arrC.chop_trailing_singletons();

  // return result array
  return arrC;

}

// decipher matrix multiplication transpose/conjugate operators
int trans_conj_op(const std::string& op) {
  if (op.compare("") == 0)
    return 0;
  else if (op.compare(".'") == 0)
    return Trans;
  else if (op.compare("'") == 0)
    return Conj | Trans;
  else
    return -1;
}

// templated worker function
template<class C, class A, class B>
octave_value do_matmap_1(const octave_value_list& args) {

  // extract the arrays
  ArrayN<A> arrA = FromValue<ArrayN<A> >(args(1));
  ArrayN<B> arrB = FromValue<ArrayN<B> >(args(2));

  // arrays must have at must 3 non-singleton dimensions
  arrA.chop_trailing_singletons();
  arrB.chop_trailing_singletons();
  if (arrA.ndims() > 3 || arrB.ndims() > 3) {
    error("matmap: arguments #2 and #3 must be 3-D arrays!");
    return octave_value();
  }

  // reshape arrays to be at least 3 dimensions
  dim_vector dimA = arrA.dims();
  dim_vector dimB = arrB.dims();
  dimA.resize(3, 1);
  dimB.resize(3, 1);
  arrA = arrA.reshape(dimA);
  arrB = arrB.reshape(dimB);

  // check that 3rd dimensions are the same length, allowing singletons
  const int nA = arrA.dims()(2);
  const int nB = arrB.dims()(2);
  if (nA != nB && nA != 1 && nB != 1) {
    error("matmap: arguments #2 and #3 must have the same 3rd dimension size!");
    return octave_value();
  }

  // first argument must be function handle/name or operator
  if (args(0).is_function_handle() || args(0).is_inline_function()) {
    return octave_value(do_matmap_2<C>(MapFunction<octave_function*,C,A,B>(args(0).function_value()), arrA, arrB));
  }
  else if (args(0).is_string()) {
    const std::string s = args(0).string_value();
    size_t i = s.find_first_of("*"); 
    if (i != std::string::npos && s.find_first_not_of("*.'") == std::string::npos) {
      const int opA = trans_conj_op(s.substr(0, i));
      const int opB = trans_conj_op(s.substr(i + 1, std::string::npos));
      if (opA < 0 || opB < 0) {
	error("matmap: invalid operator '%s'!", s.c_str());
	return octave_value();
      }
      return octave_value(do_matmap_2<C>(MapMatrixMultiply<C>(opA, opB), arrA, arrB));
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
        = \"*\"     for f(a,b) = a  *b  \n\
        = \"*'\"    for f(a,b) = a  *b' \n\
        = \"*.'\"   for f(a,b) = a  *b.'\n\
        = \"'*\"    for f(a,b) = a' *b  \n\
        = \".'*\"   for f(a,b) = a.'*b  \n\
        = \"'*'\"   for f(a,b) = a' *b' \n\
        = \"'*.'\"  for f(a,b) = a' *b.'\n\
        = \".'*'\"  for f(a,b) = a.'*b' \n\
        = \".'*.'\" for f(a,b) = a.'*b.'\n\
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
