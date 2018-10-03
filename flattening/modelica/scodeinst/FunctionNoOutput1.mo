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
  f(time);
equation
  f(time);
end FunctionNoOutput1;

// Result:
// function f
//   input Real x;
// end f;
//
// class FunctionNoOutput1
// equation
//   f(time);
// algorithm
//   f(time);
// end FunctionNoOutput1;
// endResult
