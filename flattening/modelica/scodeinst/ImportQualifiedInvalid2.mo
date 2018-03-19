// name:     ImportQualifiedInvalid2
// keywords: qualified import
// status:   incorrect
// cflags:   -d=newInst
//
// Checks that imports are really lookup up from the top scope.
//

model ImportQualifiedInvalid2
  package P
    model M
      Real x;
    end M;
  end P;

  import P.M;
  M m;
end ImportQualifiedInvalid2;

// Result:
// Error processing file: ImportQualifiedInvalid2.mo
// [flattening/modelica/scodeinst/ImportQualifiedInvalid2.mo:16:3-16:13:writable] Error: Import P.M not found in scope <top>.
// [flattening/modelica/scodeinst/ImportQualifiedInvalid2.mo:17:3-17:6:writable] Error: Class M not found in scope ImportQualifiedInvalid2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
