// name: InnerOuterInvalidMod2
// keywords: 
// status: incorrect
// cflags: -d=newInst
//

model A
  outer Real x;
end A;

model InnerOuterInvalidMod2
  inner Real x = 2.0;
  A a(x = 1.0);
end InnerOuterInvalidMod2;

// Result:
// Error processing file: InnerOuterInvalidMod2.mo
// [flattening/modelica/scodeinst/InnerOuterInvalidMod2.mo:8:3-8:15:writable] Error: Modifier '= 1.0' found on outer element x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
