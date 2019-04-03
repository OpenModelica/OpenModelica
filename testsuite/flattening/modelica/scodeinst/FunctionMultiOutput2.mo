// name: FunctionMultiOutput2
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real x;
  output Real a = x * 2;
  output Real b = x * 3;
  output Real c = x * 4;
end f;

model FunctionMultiOutput2
  Real x;
algorithm
  x := f(x);
end FunctionMultiOutput2;

// Result:
// function f
//   input Real x;
//   output Real a = x * 2.0;
//   output Real b = x * 3.0;
//   output Real c = x * 4.0;
// end f;
//
// class FunctionMultiOutput2
//   Real x;
// algorithm
//   x := f(x)[1];
// end FunctionMultiOutput2;
// endResult
