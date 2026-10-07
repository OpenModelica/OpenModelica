// name: InputDeclType
// keywords: input
// status: correct
//
// Tests the input prefix on a regular type
//

class InputDeclType
  input Real rInput = 1.0;
end InputDeclType;

// Result:
// class InputDeclType
//   input Real rInput = 1.0;
// end InputDeclType;
// [flattening/modelica/declarations/InputDeclType.mo:9:3-9:26:writable] Warning: Components are deprecated in class.
//
// endResult
