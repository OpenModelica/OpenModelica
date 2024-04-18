// name:     ImportInCompositeName1
// keywords: import lookup
// status:   incorrect
// cflags:   -d=newInst
//
//

model A
  type MyType = Real[3];
end A;

model B
  import A.MyType;
end B;

model ImportInCompositeName1
  B.MyType m;
end ImportInCompositeName1;

// Result:
// Error processing file: ImportInCompositeName1.mo
// [flattening/modelica/scodeinst/ImportInCompositeName1.mo:17:3-17:13:writable] Error: Found imported name 'MyType' while looking up composite name 'B.MyType'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
