// name: Visibility4
// keywords:
// status: incorrect
//

model A
  protected function f
    output Real x = 1.0;
  end f;
end A;

model Visibility4
  A a;
  Real x = a.f();
end Visibility4;

// Result:
// Error processing file: Visibility4.mo
// [flattening/modelica/scodeinst/Visibility4.mo:7:13-9:8:writable] Error: Illegal access of protected element f.
// [flattening/modelica/scodeinst/Visibility4.mo:14:3-14:17:writable] Error: Function a.f not found in scope Visibility4.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
