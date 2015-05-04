// name:     TestFill.mo [BUG: https://trac.openmodelica.org/OpenModelica/ticket/2113]
// keywords: array fill
// status:   correct
//
// Test that fill has integer second argument but not necessary a parameter.
//


model test
  Real y[5];
  Integer n;

algorithm
  n := 0;
  y := fill(1, 5);
  n := n + 2;
  y[1:n] := fill(2, n);
end test;

// Result:
// class test
//   Real y[1];
//   Real y[2];
//   Real y[3];
//   Real y[4];
//   Real y[5];
//   Integer n;
// algorithm
//   n := 0;
//   y := {1.0, 1.0, 1.0, 1.0, 1.0};
//   n := 2 + n;
//   y[1:n] := fill(2.0, n);
// end test;
// endResult
