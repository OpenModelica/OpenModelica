// name:     Encapsulated3
// keywords: encapsulated
// status:   incorrect
//
// An encapsulated class cannot access
// elements in enclosing scopes.

encapsulated package A
  package B
    model C
      Real x;
    end C;
  end B;
  encapsulated package B1
    import A.*;
    encapsulated model C2
      extends B.C(x=2); // Error B.C not found.
    end C2;
  end B1;
end A;


encapsulated model Encapsulated3
  import A.B.*;
  import A.B1.C2;
  C c(x=1);
  C2 c2; // Causes infitite loop
end Encapsulated3;
// Result:
// Error processing file: Encapsulated3.mo
// [flattening/modelica/packages/Encapsulated3.mo:17:7-17:23:writable] Error: Base class B.C not found in scope A.B1.C2.
// Error: Error occurred while flattening model Encapsulated3
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
