// name: ModelAccess
// keywords: model
// status: correct
//
// Tests access operator .
//

model OtherModel
  parameter Integer i1 = 8;
  parameter Integer i2 = 12;
end OtherModel;

model ModelAccess
  OtherModel om;
  Integer i1;
  Integer i2;
equation
  i1 = om.i1;
  i2 = om.i2;
end ModelAccess;

// Result:
// class ModelAccess
//   parameter Integer om.i1 = 8;
//   parameter Integer om.i2 = 12;
//   Integer i1;
//   Integer i2;
// equation
//   i1 = om.i1;
//   i2 = om.i2;
// end ModelAccess;
// endResult
