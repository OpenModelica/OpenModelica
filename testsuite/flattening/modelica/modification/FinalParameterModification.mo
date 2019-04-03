// name:     FinalParameterModification
// keywords: final, parameter, modifications
// status:   correct
//
// Tests modifications of final parameters.
// Fix for bug #1193: http://openmodelica.ida.liu.se:8080/cb/issue/1193
//

model FinalParameterModification
  final parameter Real p[3](each unit="1", each fixed=false);
  Real x(start = 1);
equation
  der(x) = -p[1] * x;
end FinalParameterModification;

// Result:
// class FinalParameterModification
//   final parameter Real p[1](unit = "1", fixed = false);
//   final parameter Real p[2](unit = "1", fixed = false);
//   final parameter Real p[3](unit = "1", fixed = false);
//   Real x(start = 1.0);
// equation
//   der(x) = (-p[1]) * x;
// end FinalParameterModification;
// endResult
