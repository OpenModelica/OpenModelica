// name: InnerOuterInvalidMod3
// keywords: 
// status: incorrect
// cflags: -d=newInst
//

model A
  outer replaceable Real x;
end A;

model InnerOuterInvalidMod3
  inner Real x = 2.0;
  A a(redeclare Real x = 1.0);
end InnerOuterInvalidMod3;

// Result:
// Error processing file: InnerOuterInvalidMod3.mo
// [flattening/modelica/scodeinst/InnerOuterInvalidMod3.mo:8:3-8:27:writable] Error: Modifier 'redeclare Real x = 1.0' found on outer element x.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
