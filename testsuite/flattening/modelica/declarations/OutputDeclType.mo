// name: OutputDeclType
// keywords: output
// status: correct
// cflags: -d=-newInst
//
// Tests the output prefix on a regular type
//

class OutputDeclType
  output Real rOutput = 1.0;
end OutputDeclType;

// Result:
// class OutputDeclType
//   output Real rOutput = 1.0;
// end OutputDeclType;
// endResult
