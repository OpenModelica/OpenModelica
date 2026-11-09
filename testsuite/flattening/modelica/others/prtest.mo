// name:     prtest
// keywords: types
// status:   incorrect
//
// Checks that subscripts are handled in a correct manner int the component clause.
//
//

model Type10
  Real[3] x[2];
  Real y[3,3];
  Real ok[3];
equation
  x = y;
  ok[1]=3.0;
end Type10;

// Result:
// Error processing file: prtest.mo
// [flattening/modelica/others/prtest.mo:14:3-14:8:writable] Error: Type mismatch in equation x = y of type Real[2, 3] = Real[3, 3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
