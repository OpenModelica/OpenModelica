// name:     ImportSubPackage1
// keywords: import
// status:   correct
// cflags:   -d=newInst
//
//

package P1
  package P2
    model A
      Real x;
    end A;
  end P2;

  import P1.P2.A;
end P1;

model M
  P1.A a;
end M;

// Result:
// class M
//   Real a.x;
// end M;
// endResult
