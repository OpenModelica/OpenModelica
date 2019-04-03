// name: ExternalFunctionInvalidSection1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
  external "C" y = ext(x);
end f;

function f2
  extends f;
algorithm
  y := x;
end f2;

model ExternalFunctionInvalidSection1
  Real x;
algorithm
  x := f2(1.0);
end ExternalFunctionInvalidSection1;

// Result:
// Error processing file: ExternalFunctionInvalidSection1.mo
// [flattening/modelica/scodeinst/ExternalFunctionInvalidSection1.mo:14:1-18:7:writable] Error: Function f2 has more than one algorithm section or external declaration.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
