// name: NonexistentRedeclareModifier2
// keywords:
// status: incorrect
//

model M
end M;

model NonexistentRedeclareModifier2
  extends M(redeclare Real x);
end NonexistentRedeclareModifier2;

// Result:
// Error processing file: NonexistentRedeclareModifier2.mo
// [flattening/modelica/scodeinst/NonexistentRedeclareModifier2.mo:10:13-10:29:writable] Error: Modified element x not found in class M.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
