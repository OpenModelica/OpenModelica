// name:     DuplicateElementsExtends
// keywords: check if duplicate elements one from extends are equivalent!
// status:   incorrect
// cflags: -d=-newInst


package Crap
  type X = Real;
  type Y = Real;
end Crap;

model Duplicate
 Crap.Y x;
end Duplicate;

model DuplicateElementsExtends
 extends Duplicate; // have another x
 import C=Crap;
 C.X x;
end DuplicateElementsExtends;

// Result:
// Error processing file: DuplicateElementsExtends.mo
// [flattening/modelica/others/DuplicateElementsExtends.mo:19:2-19:7:writable] Notification: From here:
// [flattening/modelica/others/DuplicateElementsExtends.mo:13:2-13:10:writable] Error: Duplicate elements (due to inherited elements) not identical:
//   first element is:  .Crap.X x
//   second element is: .Crap.Y x
// Error: Error occurred while flattening model DuplicateElementsExtends
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
