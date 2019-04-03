// name:     ReplaceableBaseClass
// keywords: redeclare, replaceable, extends
// status:   incorrect
//
// Checks that the compiler gives an error if the base class in an extends
// clause is replaceable.
//

model M
  replaceable type T = Real;
  extends T;
end M;

model ReplaceableBaseClass
  M m(redeclare type T = Integer);
end ReplaceableBaseClass;

// Result:
// Error processing file: ReplaceableBaseClass.mo
// [ReplaceableBaseClass.mo:11:3-11:12:writable] Notification: From here:
// [ReplaceableBaseClass.mo:10:15-10:28:writable] Error: Base class T is replaceable.
// Error: Error occurred while flattening model ReplaceableBaseClass
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
