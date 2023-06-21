// name:     ImportSubPackage1
// keywords: import
// status:   incorrect
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
// Error processing file: ImportSubPackage1.mo
// [flattening/modelica/scodeinst/ImportSubPackage1.mo:19:3-19:9:writable] Error: Found imported name 'A' while looking up composite name 'P1.A'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
