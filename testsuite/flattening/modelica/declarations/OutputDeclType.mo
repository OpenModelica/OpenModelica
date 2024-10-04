// name: OutputDeclType
// keywords: output
// status: correct
//
// Tests the output prefix on a regular type
//

class OutputDeclType
  output Real rOutput = 1.0;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end OutputDeclType;

// Result:
// class OutputDeclType
//   output Real rOutput = 1.0;
// end OutputDeclType;
// endResult
