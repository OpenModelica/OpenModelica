// name: ExtendImport2
// keywords:
// status: correct
// cflags: -d=newInst
//

package P1
  import P2;
end P1;

package P2
  import P3;
end P2;

package P3
  model A
    Real x;
  end A;
end P3;

model ExtendImport2
  extends P1.P2.P3.A;
end ExtendImport2;

// Result:
// class ExtendImport2
//   Real x;
// end ExtendImport2;
// endResult
