// name: OutputDeclRecord
// keywords: output
// status: correct
//
// Tests the output prefix on a record type
//

record OutputRecord
  Real r;
end OutputRecord;

class OutputDeclRecord
  output OutputRecord orec;
equation
  orec.r = 1.0;
end OutputDeclRecord;

// Result:
// class OutputDeclRecord
//   Real orec.r;
// equation
//   orec.r = 1.0;
// end OutputDeclRecord;
// [flattening/modelica/declarations/OutputDeclRecord.mo:13:3-13:27:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/OutputDeclRecord.mo:15:3-15:15:writable] Warning: Equation sections are deprecated in class.
//
// endResult
