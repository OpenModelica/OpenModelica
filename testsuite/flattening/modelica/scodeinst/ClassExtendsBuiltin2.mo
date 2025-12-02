// name: ClassExtendsBuiltin2
// keywords:
// status: incorrect
//

model A
  type MyReal = Real;
end A;

model ClassExtendsBuiltin2
  extends A;

  redeclare type extends MyReal
    Real y = 2.0;
  end MyReal;

  MyReal x;
end ClassExtendsBuiltin2;

// Result:
// Error processing file: ClassExtendsBuiltin2.mo
// [flattening/modelica/scodeinst/ClassExtendsBuiltin2.mo:13:13-15:13:writable] Error: A class extending from builtin type MyReal may not have other elements.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
