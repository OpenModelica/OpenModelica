// name:     ModifyConstant3
// keywords: scoping,modification
// status:   incorrect
//
// Only declared members may be redeclared. Using A.c in a redeclaration
// is a syntactic error.
//

class A
  constant Real c = 1.0;
end A;

class B
  A a(redeclare constant Real A.c = 2.0);
end B;

class C
  A a;
end C;

class ModifyConstant3
  B b;
  C c;
end ModifyConstant3;

// Result:
// Error processing file: ModifyConstant3.mo
// Failed to parse file: ModifyConstant3.mo!
//
// [openmodelica/parser/ModifyConstant3.mo:14:32-14:32:writable] Error: Missing token: ')'
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// Failed to parse file: ModifyConstant3.mo!
//
// Execution failed!
// endResult
