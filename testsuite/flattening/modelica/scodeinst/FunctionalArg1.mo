// name: FunctionalArg1
// keywords:
// status: correct
// cflags: -d=newInst
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
  y := f(x);
end f1;

function f2
  input Real x;
  output Real y = x * 2;
end f2;

model FunctionalArg1
  Real x = f1(f2, 1);
end FunctionalArg1;

// Result:
// function f1
//   input f<function>(#Real x) => #Real f;
//   input Real x;
//   output Real y;
// algorithm
//   y := unbox(f(#(x)));
// end f1;
//
// function f2
//   input Real x;
//   output Real y = x * 2.0;
// end f2;
//
// class FunctionalArg1
//   Real x = f1(f2, 1.0);
// end FunctionalArg1;
// endResult
