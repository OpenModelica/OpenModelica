// name: const11.mo
// keywords:
// status: correct
// cflags: -d=newInst
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
// class M
//   Integer x = 2;
//   constant Integer a.j = 3;
//   Integer y = 3;
//   constant Integer b.i = 2;
//   Integer z = 2;
//   constant Integer j = 2;
//   Integer w = 2;
//   Integer v = 2;
// end M;
// endResult
