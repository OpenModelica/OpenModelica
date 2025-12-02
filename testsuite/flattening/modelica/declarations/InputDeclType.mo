// name: InputDeclType
// keywords: input
// status: correct
//
// Tests the input prefix on a regular type
//

class InputDeclType
  input Real rInput = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end InputDeclType;

// Result:
// class InputDeclType
//   input Real rInput = 1.0;
// end InputDeclType;
// endResult
