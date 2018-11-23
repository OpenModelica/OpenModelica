// name: PartialApplicationInvalidArg2
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

model PartialApplicationInvalidArg2
  Real x = f2(time, function f1(z = 2.0));  
end PartialApplicationInvalidArg2;

// Result:
// Error processing file: PartialApplicationInvalidArg2.mo
// [flattening/modelica/scodeinst/PartialApplicationInvalidArg2.mo:30:3-30:42:writable] Error: Function f1 has no input parameter named z.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
