// name: const11.mo
// keywords:
// status: correct
// cflags:   -d=newInst
//
// FAILREASON: Fails since package constants in classes which are not explicitly
//             declared as packages are not instantiated.
//

package P
  class A
    constant Integer j = 2;

    class B
      constant Integer i = j;
    end B;
  end A;

  model C
    Integer x = P.A.B.i;
    A a(j = 3);
    Integer y = a.j;
    A.B b;
    Integer z = b.i;
  end C;

  model D
    extends A;
    Integer w = j;
    Integer v = B.i;
  end D;
end P;

model M
  extends P.C;
  extends P.D;
end M;

// Result:
//
// EXPANDED FORM:
//
// class M
//   Integer v = 2;
//   Integer w = 2;
//   Integer z = 2;
//   Integer y = 3;
//   Integer x = 2;
// end M;
//
//
// Found 5 components and 0 parameters.
// class M
//   Integer x = 2;
//   constant Integer a.j = 3;
//   Integer y = 2;
//   constant Integer b.i = 2;
//   Integer z = 2;
//   constant Integer j = 2;
//   Integer w = 2;
//   Integer v = 2;
// end M;
// endResult
