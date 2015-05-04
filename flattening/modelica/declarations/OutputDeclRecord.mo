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
// function OutputRecord "Automatically generated record constructor for OutputRecord"
//   input Real r;
//   output OutputRecord res;
// end OutputRecord;
//
// class OutputDeclRecord
//   output Real orec.r;
// equation
//   orec.r = 1.0;
// end OutputDeclRecord;
// endResult
