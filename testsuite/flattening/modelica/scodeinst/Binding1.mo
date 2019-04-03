// name: Binding1.mo
// status: correct
// cflags: -d=newInst
//
// Simple test of component bindings.
//

model Binding1
  Real x = 1.0;
end Binding1;

// Result:
// class Binding1
//   Real x = 1.0;
// end Binding1;
// endResult
