// name:     ImportConflict3
// keywords: import conflict
// status:   incorrect
// cflags:   -d=newInst
//
// Checks that using a name imported from several sources produces an error.
//

package P
  package P1
    model M
      Real x;
    end M;
  end P1;

  package P2
    model M
      Real x;
    end M;
  end P2;
end P;

model ImportConflict3
  import P.P1.*;
  import P.P2.*;
  M m;
end ImportConflict3;

// Result:
// Error processing file: ImportConflict3.mo
// [flattening/modelica/scodeinst/ImportConflict3.mo:24:3-24:16:writable] Notification: From here:
// [flattening/modelica/scodeinst/ImportConflict3.mo:25:3-25:16:writable] Error: M found in several unqualified import statements.
// [flattening/modelica/scodeinst/ImportConflict3.mo:26:3-26:6:writable] Error: Class M not found in scope ImportConflict3.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
