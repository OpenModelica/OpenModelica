// name: ArrayConstructorComplex1
// keywords:
// status: correct
//

operator record Complex  "Complex number with overloaded operators"
  replaceable Real re "Real part of complex number";
  replaceable Real im "Imaginary part of complex number";
end Complex;

model ArrayConstructorComplex1
  Complex[3] u;
  Complex[3] uInternal = {if false then u[k] else u[k] for k in 1:3};
end ArrayConstructorComplex1;

// Result:
// class ArrayConstructorComplex1
//   Real u[1].re "Real part of complex number";
//   Real u[1].im "Imaginary part of complex number";
//   Real u[2].re "Real part of complex number";
//   Real u[2].im "Imaginary part of complex number";
//   Real u[3].re "Real part of complex number";
//   Real u[3].im "Imaginary part of complex number";
//   Real uInternal[1].re = u[1].re "Real part of complex number";
//   Real uInternal[1].im = u[1].im "Imaginary part of complex number";
//   Real uInternal[2].re = u[2].re "Real part of complex number";
//   Real uInternal[2].im = u[2].im "Imaginary part of complex number";
//   Real uInternal[3].re = u[3].re "Real part of complex number";
//   Real uInternal[3].im = u[3].im "Imaginary part of complex number";
// end ArrayConstructorComplex1;
// endResult
