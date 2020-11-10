// name: InputDeclType
// keywords: input
// status: correct
// cflags: -d=-newInst
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
// endResult
