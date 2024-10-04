// name: ExtendsVisibility4
// keywords: extends visibility
// status: incorrect
//

model A
  function f
    output Real x = 1.0;
  end f;
end A;

model B
protected
  extends A;
end B;

model ExtendsVisibility4
  Real x = b.f();
  B b;
end ExtendsVisibility4;

// Result:
// Error processing file: ExtendsVisibility4.mo
// [flattening/modelica/scodeinst/ExtendsVisibility4.mo:7:3-9:8:writable] Error: Illegal access of protected element f.
// [flattening/modelica/scodeinst/ExtendsVisibility4.mo:18:3-18:17:writable] Error: Function b.f not found in scope ExtendsVisibility4.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
