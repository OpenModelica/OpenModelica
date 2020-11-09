// name:     ModifyConstant4
// keywords: scoping,modification
// status:   incorrect
// cflags: -d=-newInst
//
// Only members may be modified.
//

class A
  constant Real c = 1.0;
end A;

class B
  A a(A.c = 2.0);
end B;

class C
  A a;
end C;

class ModifyConstant4
  B b;
  C c;
end ModifyConstant4;
// Result:
// Error processing file: ModifyConstant4.mo
// [flattening/modelica/modification/ModifyConstant4.mo:14:3-14:17:writable] Error: Variable b.a: In modifier (A(c = 2.0), class or component c), class or component A not found in <A$b$a>.
// Error: Error occurred while flattening model ModifyConstant4
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
