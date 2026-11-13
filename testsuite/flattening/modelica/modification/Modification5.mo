// name:     Modification5
// keywords: modification,scoping
// status:   correct
//
// By removing the declare-before-use this is legal in Modelica.
// Note that declaration equation are seen as equation and
// not as assignments.

class A
  Real x = 17 + 2*x;
end A;

class Modification5
  extends A;
end Modification5;

// Result:
// class Modification5
//   Real x = 17.0 + 2.0 * x;
// end Modification5;
// endResult
