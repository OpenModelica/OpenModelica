// name:     ImportSubPackage2
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

  import P1.P2;
  extends P2;
end P1;

model ImportSubPackage2
  P1.A a;
end ImportSubPackage2;

// Result:
// class ImportSubPackage2
//   Real a.x;
// end ImportSubPackage2;
// endResult
