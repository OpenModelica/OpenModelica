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
  parameter Real b[n](each fixed = true) = {1, 2};
initial equation
  a = b;
end FixedFalse;

// Result:
// class FixedFalse
//   final parameter Integer n = 2;
//   parameter Real a[1](fixed = false);
//   parameter Real a[2](fixed = false);
//   parameter Real b[1](fixed = true) = 1.0;
//   parameter Real b[2](fixed = true) = 2.0;
// initial equation
//   a[1] = b[1];
//   a[2] = b[2];
// end FixedFalse;
// endResult
