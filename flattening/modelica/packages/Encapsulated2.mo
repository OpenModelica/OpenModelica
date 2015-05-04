// name:     Encapsulated2
// keywords: encapsulated
// status:   incorrect
//
// An encapsulate class requires import to access
// even top-level classes.

encapsulated package A
  package B
    model C
      Real x;
    end C;
  end B;
  encapsulated package B1
    import A.*;
    model C2=B.C(x=2);
  end B1;
end A;


encapsulated model Encapsulated2
  // Error: No import.
  A.B.C c(x=1);
  A.B1.C2 c2;
end Encapsulated2;
// Result:
// Error processing file: Encapsulated2.mo
// [flattening/modelica/packages/Encapsulated2.mo:23:3-23:15:writable] Error: Class A.B.C not found in scope Encapsulated2.
// Error: Error occurred while flattening model Encapsulated2
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
