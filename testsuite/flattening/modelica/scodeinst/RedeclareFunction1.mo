// name: RedeclareFunction1
// keywords:
// status: correct
//

package P
  replaceable function f
  end f;
end P;

function f
  input Real x;
  output Real y;
algorithm
  y := x;
end f;

model RedeclareFunction1
  package P = .P(redeclare function f = .f);
  Real x = P.f(4);
end RedeclareFunction1;

// Result:
// class RedeclareFunction1
//   Real x = 4.0;
// end RedeclareFunction1;
// endResult
