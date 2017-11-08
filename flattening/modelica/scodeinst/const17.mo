// name: const17.mo
// keywords:
// status: correct
// cflags: -d=newInst
//
//

package A
  package B
    constant Integer i = A.B.c;

    package A
      package B
        constant Integer c = 2;
      end B;
    end A;
  end B;
end A;

model M
  Real x = A.B.i;
end M;

// Result:
// class M
//   constant Integer A.B.i = A.B.A.B.c;
//   constant Integer A.B.A.B.c = 2;
//   Real x = /*Real*/(A.B.i);
// end M;
// endResult
