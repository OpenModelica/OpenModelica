// name:     DeclareConstant3
// keywords: declaration
// status:   incorrect
//
// A constant requires a declaration equation with constant
// expression on the right hand side.
//

class DeclareConstant3
  Real x, y;
  constant Real c = x + y;
equation
  c = 5.0;
end DeclareConstant3;

// Result:
// Error processing file: DeclareConstant3.mo
// [flattening/modelica/declarations/DeclareConstant3.mo:10:3-10:12:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/DeclareConstant3.mo:11:3-11:26:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/DeclareConstant3.mo:13:3-13:10:writable] Warning: Equation sections are deprecated in class.
// [flattening/modelica/declarations/DeclareConstant3.mo:11:3-11:26:writable] Error: Component c of variability constant has binding 'x + y' of higher variability continuous.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
