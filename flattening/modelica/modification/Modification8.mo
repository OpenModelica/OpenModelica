// name:     Modification8
// keywords: modification
// status:   incorrect
//
// These are seen as two modifications of the
// same element.
//
// The 23rd meeting at Lund clarified that
// a.x=1.0, a.y=2, a(z=3) is seen as a(x=1.0,y=2,z=3)
//

class Modification8
  class A
    Real x;
  end A;
  class B
    A a;
  end B;
  B b(a.x = 1.0, a(x = 2.0));
end Modification8;

// Result:
// Error processing file: Modification8.mo
// [flattening/modelica/modification/Modification8.mo:19:7-19:16:writable] Notification: From here:
// [flattening/modelica/modification/Modification8.mo:19:20-19:27:writable] Error: Duplicate modification of element a.x on component b.
// Error: Error occurred while flattening model Modification8
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
