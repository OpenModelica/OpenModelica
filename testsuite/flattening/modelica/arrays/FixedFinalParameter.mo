// name:     FixedFinalParameter
// keywords: fixed, final, parameter, array, initial equation
// status:   correct
//
// Tests fixed=false for final array parameters with initial equations.
//
// Tests fix for bug #1194: http://openmodelica.ida.liu.se:8080/cb/issue/1194
//

model FixedFinalParameter
  final parameter Real p[3](each fixed = false);
initial equation
  p = {1.0, 2.0, 3.0};
end FixedFinalParameter;

// Result:
// class FixedFinalParameter
//   final parameter Real p[1](fixed = false);
//   final parameter Real p[2](fixed = false);
//   final parameter Real p[3](fixed = false);
// initial equation
//   p[1] = 1.0;
//   p[2] = 2.0;
//   p[3] = 3.0;
// end FixedFinalParameter;
// endResult
