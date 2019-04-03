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
//   Real x = 2.0;
// end M;
// endResult
