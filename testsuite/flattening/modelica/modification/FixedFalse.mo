// name:     FixedFalse [BUG: https://trac.openmodelica.org/OpenModelica/ticket/1983]
// keywords: fixed, parameter, modifications
// status:   correct
//
// Tests modifications of final parameters.
// Fix for bug #1983.
//

model FixedFalse
  parameter Integer n = 2;
  parameter Real a[n](each fixed = false);
  parameter Real b[n](each fixed = true);
initial equation
  a = b;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end FixedFalse;

// Result:
// class FixedFalse
//   parameter Integer n = 2;
//   parameter Real a[1](fixed = false);
//   parameter Real a[2](fixed = false);
//   parameter Real b[1](fixed = true);
//   parameter Real b[2](fixed = true);
// initial equation
//   a[1] = b[1];
//   a[2] = b[2];
// end FixedFalse;
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
//
// endResult
