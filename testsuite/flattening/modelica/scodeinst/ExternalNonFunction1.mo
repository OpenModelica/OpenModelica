// name: ExternalNonFunction1
// keywords: external
// status: incorrect
//
// Checks that non-functions are not allowed to have external sections.
//

model ExternalNonFunction1
  external "C" test();
end ExternalNonFunction1;

// Result:
// Error processing file: ExternalNonFunction1.mo
// [flattening/modelica/scodeinst/ExternalNonFunction1.mo:8:1-10:25:writable] Error: Class specialization violation: ExternalNonFunction1 is a model, which may not contain an external declaration.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
