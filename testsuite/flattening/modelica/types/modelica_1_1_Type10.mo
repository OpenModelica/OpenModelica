// name:     modelica_1_1_Type10
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
// Error processing file: modelica_1_1_Type10.mo
// [flattening/modelica/types/modelica_1_1_Type10.mo:10:3-10:15:writable] Warning: Components are deprecated in class.
// [flattening/modelica/types/modelica_1_1_Type10.mo:11:3-11:14:writable] Warning: Components are deprecated in class.
// [flattening/modelica/types/modelica_1_1_Type10.mo:12:3-12:13:writable] Warning: Components are deprecated in class.
// [flattening/modelica/types/modelica_1_1_Type10.mo:14:3-14:8:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/types/modelica_1_1_Type10.mo:14:3-14:8:writable] Error: Type mismatch in equation x = y of type Real[2, 3] = Real[3, 3].
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
