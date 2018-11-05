// name: FunctionalArgInvalidType1
// keywords:
// status: incorrect
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
  input Integer x;
  output Integer y = x * 2;
end f2;

model FunctionalArgInvalidType1
  Real x = f1(f2, 1);
end FunctionalArgInvalidType1;

// Result:
// Error processing file: FunctionalArgInvalidType1.mo
// [flattening/modelica/scodeinst/FunctionalArgInvalidType1.mo:26:3-26:21:writable] Error: Type mismatch for positional argument 1 in f1(f=f2). The argument has type:
//   f2<function>(Integer) => Integer
// expected type:
//   f<function>(#Real) => #Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
