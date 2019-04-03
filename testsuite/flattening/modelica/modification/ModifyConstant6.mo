// name:     ModifyConstant6
// keywords: scoping,modification
// status:   incorrect
//
// Finalized constants can not be modified.
//

class A
  final constant Real c = 1.0;
end A;

class B
  A a(c = 2.0);
end B;

class C
  A a;
end C;

class ModifyConstant6
  B b;
  C c;
end ModifyConstant6;


// Result:
// Error processing file: ModifyConstant6.mo
// [ModifyConstant6.mo:13:3-13:15:writable] Error: Variable b.a: Trying to override final variable in component b.a and scope A by using modifiers:  = (typed)2.0 DAE.PROP(Real, C_CONST), value: 2.0 and final  = (typed)1.0 DAE.PROP(Real, C_CONST), value: 1.0 that do not agree.
// Error: Error occurred while flattening model ModifyConstant6
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
