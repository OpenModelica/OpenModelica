// name: FunctionNoOutput1
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real x;
end f;

model FunctionNoOutput1
algorithm
  f(1.0);
equation
  f(2.0);
end FunctionNoOutput1;

// Result:
// function f
//   input Real x;
// end f;
//
// class FunctionNoOutput1
// equation
//   f(2.0);
// algorithm
//   f(1.0);
// end FunctionNoOutput1;
// endResult
