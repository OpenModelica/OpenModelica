// name: ParameterDeclRecord
// keywords: parameter
// status: correct
//
// Tests the parameter prefix on a record type
//

record ParameterRecord
  Real r;
end ParameterRecord;

model ParameterDeclRecord
  parameter ParameterRecord pr(r(fixed = false));
initial equation
  pr.r = 1.0;
end ParameterDeclRecord;

// Result:
// class ParameterDeclRecord
//   parameter Real pr.r(fixed = false);
// initial equation
//   pr.r = 1.0;
// end ParameterDeclRecord;
// endResult
