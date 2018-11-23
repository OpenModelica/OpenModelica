// name: PartialApplicationInvalidArg1
// keywords:
// status: incorrect
// cflags: -d=newInst
//

function f1
  input Real x;
  input Real y;
  output Real z = x + y;
end f1;

partial function pf
  input Real x;
  output Real z;
end pf;

function f2
  input Real x;
  input pf func; 
  output Real z = x * func(x);
end f2;

function f3
  input Real x;
  output Real z = x;
end f3;

model PartialApplicationInvalidArg1
  Real x = f2(time, function f1(y = "fish"));  
end PartialApplicationInvalidArg1;

// Result:
// Error processing file: PartialApplicationInvalidArg1.mo
// [flattening/modelica/scodeinst/PartialApplicationInvalidArg1.mo:30:3-30:45:writable] Error: Type mismatch for named argument in f1(y="fish"). The argument has type:
//   String
// expected type:
//   Real
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
