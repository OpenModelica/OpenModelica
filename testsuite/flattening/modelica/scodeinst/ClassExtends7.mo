// name: ClassExtends7
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  constant Real px = 1.0;

  model A
    Real x;
  end A;

  model B
    replaceable model C
      A a(x = px);
    end C;
  end B;
end P;

model ClassExtends7
  extends P.B;

  redeclare model extends C
    Real y;
  end C;

  C c;
end ClassExtends7;

// Result:
// class ClassExtends7
//   Real c.a.x = 1.0;
//   Real c.y;
// end ClassExtends7;
// endResult
