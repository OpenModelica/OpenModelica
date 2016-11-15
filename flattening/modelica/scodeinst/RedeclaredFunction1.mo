// name: RedeclaredFunction1
// keywords:
// status: correct
// cflags:   -d=newInst
//

package P
  replaceable function f
  end f;
end P;

function f
  input Real x;
  output Real y;
algorithm
  x := y;
end f;

model M
  package P = .P(redeclare function f = .f);
  Real x = P.f(4);
end M;

// Result:
// function P.f
//   input Real x;
//   output Real y;
// algorithm
//   x := y;
// end P.f;
//
// class M
//   Real x = P.f(4);
// end M;
// endResult
