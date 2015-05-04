// name:     prtest
// keywords: types
// status:   incorrect
//
// Checks that subscripts are handled in a correct manner int the component clause.
//
//

class Type10
  Real[3] x[2];
  Real y[3,3];
  Real ok[3];
equation
  x = y;
  ok[1]=3.0;
end Type10;

// Result:
// Error processing file: prtest.mo
// [flattening/modelica/others/prtest.mo:14:3-14:8:writable] Error: Type mismatch in equation {{x[1,1], x[1,2], x[1,3]}, {x[2,1], x[2,2], x[2,3]}}={{y[1,1], y[1,2], y[1,3]}, {y[2,1], y[2,2], y[2,3]}, {y[3,1], y[3,2], y[3,3]}} of type Real[2, 3]=Real[3, 3].
// Error: Error occurred while flattening model Type10
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
