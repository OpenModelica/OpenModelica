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
//   constant Integer P.P.j = 2;
//   constant Integer P.P.P.i = P.P.j;
//   Real x = /*Real*/(P.P.P.i);
// end M;
// endResult
