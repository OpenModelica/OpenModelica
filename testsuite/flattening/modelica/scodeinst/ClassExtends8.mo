// name: ClassExtends8
// keywords:
// status: correct
// cflags: -d=newInst
//

package P1
  replaceable model M
    Real x;
  end M;
end P1;

package P2
  extends P1;

  redeclare model extends M
    Real y;
  end M;
end P2;

model ClassExtends8
  package PA = P2;
  package PB = P2;

  PA.M m1;
  PB.M m2;
end ClassExtends8;

// Result:
// class ClassExtends8
//   Real m1.x;
//   Real m1.y;
//   Real m2.x;
//   Real m2.y;
// end ClassExtends8;
// endResult
