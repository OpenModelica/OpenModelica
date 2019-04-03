// name: InnerOuterInvalidMod1
// keywords: 
// status: incorrect
// cflags: -d=newInst
//

model A
  outer Real x = 1.0;
end A;

model InnerOuterInvalidMod1
  inner Real x = 2.0;
  A a;
end InnerOuterInvalidMod1;

// Result:
// Error processing file: InnerOuterInvalidMod1.mo
// [flattening/modelica/scodeinst/InnerOuterInvalidMod1.mo:8:3-8:21:writable] Error: Modifier '= 1.0' found on outer element x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
