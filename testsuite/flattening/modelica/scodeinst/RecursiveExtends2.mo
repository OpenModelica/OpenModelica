// name: RecursiveExtends2
// keywords:
// status: incorrect
// cflags: -d=newInst
//
// Checks that the compiler catches recursive extends.
//

model A
  model B
    extends A;
    Real x;
  end B;

  B b;
end A;

model RecursiveExtends2
  extends A.B;
end RecursiveExtends2;

// Result:
// Error processing file: RecursiveExtends2.mo
// [flattening/modelica/scodeinst/RecursiveExtends2.mo:11:5-11:14:writable] Error: extends A causes an instantiation loop.
// [flattening/modelica/scodeinst/RecursiveExtends2.mo:19:3-19:14:writable] Error: Base class A.B not found in scope RecursiveExtends2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
