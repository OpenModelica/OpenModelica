// name: ExtendImport1
// keywords:
// status: correct
// cflags: -d=newInst
//

package P1
  package P2
    model A
      Real x;
    end A;
  end P2;
end P1;

model ExtendImport1
  import P1.P2.A;
  extends A;
end ExtendImport1;

// Result:
// class ExtendImport1
//   Real x;
// end ExtendImport1;
// endResult
