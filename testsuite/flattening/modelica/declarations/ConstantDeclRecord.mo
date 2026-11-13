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
// class ConstantDeclRecord
//   constant Real cr.r = 2.0;
// end ConstantDeclRecord;
// endResult
