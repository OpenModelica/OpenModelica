// name: CevalArrayConstructor3
// keywords:
// status: correct
//
//

model CevalArrayConstructor3
  parameter Real x[3] = {2, 2, 2};
  parameter Real y[:] = {sum(x[1:i]) for i in 1:2} annotation(Evaluate=true);
end CevalArrayConstructor3;

// Result:
// class CevalArrayConstructor3
//   final parameter Real x[1] = 2.0;
//   final parameter Real x[2] = 2.0;
//   final parameter Real x[3] = 2.0;
//   final parameter Real y[1] = 2.0;
//   final parameter Real y[2] = 4.0;
// end CevalArrayConstructor3;
// endResult
