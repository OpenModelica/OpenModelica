// name: ClassExtendsBuiltin1.mo
// keywords:
// status: incorrect
// cflags: -d=newInst
//

model A
  model B
    Real x;
  end B;
end A;

model ClassExtendsBuiltin1
  extends A;

  redeclare model extends B
    extends Real;
    Real y = 2.0;
  end B;

  B x;
end ClassExtendsBuiltin1;

// Result:
// Error processing file: ClassExtendsBuiltin1.mo
// [flattening/modelica/scodeinst/ClassExtendsBuiltin1.mo:17:5-17:17:writable] Error: A class extending from builtin type Real may not have other elements.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
