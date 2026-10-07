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
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
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
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
