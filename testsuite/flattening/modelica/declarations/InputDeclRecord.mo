// name: InputDeclRecord
// keywords: input
// status: correct
//
// Tests the input prefix on a record type
//

record InputRecord
  Real r;
end InputRecord;

class InputDeclRecord
  input InputRecord ir;
equation
  ir.r = 1.0;
end InputDeclRecord;

// Result:
// class InputDeclRecord
//   input Real ir.r;
// equation
//   ir.r = 1.0;
// end InputDeclRecord;
// [flattening/modelica/declarations/InputDeclRecord.mo:13:3-13:23:writable] Warning: Components are deprecated in class.
// [flattening/modelica/declarations/InputDeclRecord.mo:15:3-15:13:writable] Warning: Equation sections are deprecated in class.
//
// endResult
