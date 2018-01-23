// name: const16.mo
// keywords:
// status: correct
// cflags: -d=newInst
//

package P
  package P
    constant Integer j = 2;

    package P
      constant Integer i = j;
    end P;
  end P;

  model M
    Real x = P.P.i;
  end M;
end P;

model M
  extends P.M;
end M;

// Result:
// class M
//   Real x = 2.0;
// end M;
// endResult
