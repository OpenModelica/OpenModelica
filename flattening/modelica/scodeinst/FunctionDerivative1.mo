// name: FunctionDerivative1
// status: correct
// cflags: -d=newInst
//
//

function f1
  input Real x;
  input Real y;
  output Real z = x + y;
algorithm
  annotation(derivative = f2);
end f1;

function f2
  input Real x;
  input Real y;
  input Real der_x;
  output Real z = 0;
end f2;

model FunctionDerivative1
  Real x = f1(time, time);
end FunctionDerivative1;

// Result:
// function f1
//   input Real x;
//   input Real y;
//   output Real z = x + y;
// algorithm
// end f1;
//
// function f2
//   input Real x;
//   input Real y;
//   input Real der_x;
//   output Real z = 0.0;
// end f2;
//
// class FunctionDerivative1
//   Real x = f1(time, time);
// end FunctionDerivative1;
// endResult
