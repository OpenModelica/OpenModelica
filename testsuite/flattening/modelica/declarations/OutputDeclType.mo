// name: OutputDeclType
// keywords: output
// status: correct
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
// [flattening/modelica/declarations/OutputDeclType.mo:9:3-9:28:writable] Warning: Components are deprecated in class.
//
// endResult
