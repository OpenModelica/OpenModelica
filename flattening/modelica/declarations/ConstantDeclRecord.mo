// name: ConstantDeclRecord
// keywords: constant
// status: correct
//
// Tests the constant prefix on a record
//

record ConstantRecord
  Real r;
end ConstantRecord;

model ConstantDeclRecord
  constant ConstantRecord cr(r = 2.0);
end ConstantDeclRecord;

// Result:
// function ConstantRecord "Automatically generated record constructor for ConstantRecord"
//   input Real r;
//   output ConstantRecord res;
// end ConstantRecord;
//
// function ConstantRecord$cr "Automatically generated record constructor for ConstantRecord$cr"
//   input Real r;
//   output ConstantRecord$cr res;
// end ConstantRecord$cr;
//
// class ConstantDeclRecord
//   constant Real cr.r = 2.0;
// end ConstantDeclRecord;
// endResult
