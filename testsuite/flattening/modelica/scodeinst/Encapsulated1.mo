// name: Encapsulated1
// keywords: operator
// status: incorrect
//
// Checks that it's not allowed to look outside an encapsulated package.
//

package P1
  model A
    Real x;
  end A;

  encapsulated model B
    A a;
  end B;
end P1;

model Encapsulated1
  P1.B b;
end Encapsulated1;

// Result:
// Error processing file: Encapsulated1.mo
// [flattening/modelica/scodeinst/Encapsulated1.mo:14:5-14:8:writable] Error: Class A not found in scope B.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
