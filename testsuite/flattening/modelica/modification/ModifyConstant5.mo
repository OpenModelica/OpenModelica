// name:     ModifyConstant5
// keywords: scoping,modification
// status:   incorrect
//
// Finalized members can not be redeclared.
//

class A
  final constant Real c = 1.0;
end A;

class B
  A a(redeclare constant Real c = 2.0);
end B;

class C
  A a;
end C;

class ModifyConstant5
  B b;
  C c;
  annotation(__OpenModelica_commandLineOptions="-d=-newInst");
end ModifyConstant5;

// Result:
// Error processing file: ModifyConstant5.mo
// Warning: The old frontend (-d=-newInst) is deprecated and will be removed after OpenModelica 1.28.0 is released. Please report models that only work with the old frontend, see https://github.com/OpenModelica/OpenModelica/issues/17177.
// [flattening/modelica/modification/ModifyConstant5.mo:13:3-13:39:writable] Notification: From here:
// [flattening/modelica/modification/ModifyConstant5.mo:9:3-9:30:writable] Error: Redeclaration of final component c is not allowed.
// [flattening/modelica/modification/ModifyConstant5.mo:13:3-13:39:writable] Notification: From here:
// [flattening/modelica/modification/ModifyConstant5.mo:9:3-9:30:writable] Error: Redeclaration of constant component c is not allowed.
// Error: Error occurred while flattening model ModifyConstant5
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
