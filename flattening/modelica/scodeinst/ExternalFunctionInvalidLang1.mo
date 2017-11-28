// name: ExternalFunctionInvalidLang1
// keywords:
// status: incorrect
// cflags: -d=newInst
//
//

function f
  input Real x;
  output Real y;
  external "fish" y = ext(x);
end f;

model ExternalFunctionInvalidLang1
  Real x;
algorithm
  x := f(1.0);
end ExternalFunctionInvalidLang1;

// Result:
// Error processing file: ExternalFunctionInvalidLang1.mo
// [flattening/modelica/scodeinst/ExternalFunctionInvalidLang1.mo:8:1-12:6:writable] Error: 'fish' is not a valid language for an external function.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
