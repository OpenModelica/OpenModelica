// name: InputDeclType
// keywords: input
// status: correct
//
// Tests the input prefix on a regular type
//

model InputDeclType
  input Real rInput = 1.0;
end InputDeclType;

// Result:
// class InputDeclType
//   input Real rInput = 1.0;
// end InputDeclType;
// endResult
