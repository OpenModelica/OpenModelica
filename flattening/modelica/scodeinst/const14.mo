// name: const14.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

package B
  package A
    package B
      constant Integer j = 2;
    end B;
  end A;
end B;

package A
  package B
    package A
      package B
        constant Integer i = .B.A.B.j;
      end B;
    end A;
  end B;
end A;

model M
  Integer x = A.B.A.B.i;
end M;

// Result:
// class M
//   constant Integer B.A.B.j = 2;
//   constant Integer A.B.A.B.i = B.A.B.j;
//   Integer x = A.B.A.B.i;
// end M;
// endResult
