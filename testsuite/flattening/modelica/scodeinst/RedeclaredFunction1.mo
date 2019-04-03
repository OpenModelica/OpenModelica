// name: RedeclareFunction1
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

model RedeclareFunction1
  package P = .P(redeclare function f = .f);
  Real x = P.f(4);
end RedeclareFunction1;

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
