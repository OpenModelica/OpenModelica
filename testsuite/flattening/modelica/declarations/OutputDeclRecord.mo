// name: OutputDeclRecord
// keywords: output
// status: correct
//
// Tests that the output prefix on a top-level record component is not
// applied to its fields, see #17505.
//

record OutputRecord
  Real r;
end OutputRecord;

model OutputDeclRecord
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
// endResult
