// name: FunctionNoOutput2
// keywords:
// status: correct
// cflags: -d=newInst
//

function f
  input Real x;
  output Real y = x;
end f;

model FunctionNoOutput2
algorithm
  f(time);
equation
  f(time);
end FunctionNoOutput2;

// Result:
// function f
//   input Real x;
//   output Real y = x;
// end f;
//
// class FunctionNoOutput2
// equation
//   f(time);
// algorithm
//   f(time);
// end FunctionNoOutput2;
// [flattening/modelica/scodeinst/FunctionNoOutput2.mo:16:3-16:10:writable] Warning: Discarding return value of call to pure function ‘f‘.
// [flattening/modelica/scodeinst/FunctionNoOutput2.mo:14:3-14:10:writable] Warning: Discarding return value of call to pure function ‘f‘.
//
// endResult
