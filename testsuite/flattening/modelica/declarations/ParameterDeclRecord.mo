// name: ParameterDeclRecord
// keywords: parameter
// status: correct
//
// Tests the parameter prefix on a record type
//

record ParameterRecord
  Real r;
end ParameterRecord;

class ParameterDeclRecord
  parameter ParameterRecord pr;
equation
  pr.r = 1.0;
end ParameterDeclRecord;

// Result:
// function ParameterRecord "Automatically generated record constructor for ParameterRecord"
//   input Real r;
//   output ParameterRecord res;
// end ParameterRecord;
//
// class ParameterDeclRecord
//   parameter Real pr.r;
// equation
//   pr.r = 1.0;
// end ParameterDeclRecord;
// endResult
