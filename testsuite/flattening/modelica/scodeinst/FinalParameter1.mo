// name: FinalParameter1
// keywords:
// status: correct
// suite: disabled
//

model FinalParameter1
  final parameter Real x = 3.0;
  Real y = x;
end FinalParameter1;

// Result:
// class FinalParameter1
//   final parameter Real x = 3.0;
//   Real y = 3.0;
// end FinalParameter1;
// endResult
