// name: EqualityConstraint2
// keywords:
// status: correct
// cflags: -d=newInst
//

type Real2 = Real[2];
type Overconstrained
  extends Real2;
  function equalityConstraint
    input Real u1[2];
    input Real u2[2];
    output Real residue[1];
  algorithm
    residue[1] := u1[1] - u2[1];
  end equalityConstraint;
end Overconstrained;

connector C
  Real e;
  flow Real f;
  Overconstrained o;
  flow Real g;
end C;

model EqualityConstraint2
  C c1, c2, c3, c4;
equation
  Connections.potentialRoot(c1.o);
  Connections.branch(c1.o, c2.o);
  Connections.branch(c1.o, c3.o);
  connect(c2, c4);
  connect(c3, c4);
end EqualityConstraint2;

// Result:
// function Overconstrained.equalityConstraint
//   input Real[2] u1;
//   input Real[2] u2;
//   output Real[1] residue;
// algorithm
//   residue[1] := u1[1] - u2[1];
// end Overconstrained.equalityConstraint;
//
// class EqualityConstraint2
//   Real c1.e;
//   Real c1.f;
//   Real c1.o[1];
//   Real c1.o[2];
//   Real c1.g;
//   Real c2.e;
//   Real c2.f;
//   Real c2.o[1];
//   Real c2.o[2];
//   Real c2.g;
//   Real c3.e;
//   Real c3.f;
//   Real c3.o[1];
//   Real c3.o[2];
//   Real c3.g;
//   Real c4.e;
//   Real c4.f;
//   Real c4.o[1];
//   Real c4.o[2];
//   Real c4.g;
// equation
//   c3.e = c4.e;
//   c3.e = c2.e;
//   -(c3.f + c4.f + c2.f) = 0.0;
//   -(c3.g + c4.g + c2.g) = 0.0;
//   c3.o[1] = c4.o[1];
//   c3.o[2] = c4.o[2];
//   c1.f = 0.0;
//   c1.g = 0.0;
//   c2.f = 0.0;
//   c2.g = 0.0;
//   c3.f = 0.0;
//   c3.g = 0.0;
//   c4.f = 0.0;
//   c4.g = 0.0;
//   Overconstrained.equalityConstraint(c2.o, c4.o) = {0.0};
// end EqualityConstraint2;
// endResult
