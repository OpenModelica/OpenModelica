// name: FunctionalArgBinary1
// keywords:
// status: correct
//

partial function F
  input Real x;
  output Real y;
end F;

function f1
  input F f;
  input Real x;
  output Real y;
algorithm
  y := f(x) + f(x);
end f1;

function f2
  input Real x;
  output Real y = x * 2;
end f2;

model FunctionalArgBinary1
  Real x = f1(f2, 1);
end FunctionalArgBinary1;

// Result:
// function f1
//   input f<function>(#Real x) => #Real f;
//   input Real x;
//   output Real y;
// algorithm
//   y := unbox(f(#(x))) + unbox(f(#(x)));
// end f1;
//
// function f2
//   input Real x;
//   output Real y = x * 2.0;
// end f2;
//
// class FunctionalArgBinary1
//   Real x = f1(f2, 1.0);
// end FunctionalArgBinary1;
// endResult
