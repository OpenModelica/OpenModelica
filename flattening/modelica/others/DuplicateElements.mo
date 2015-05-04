// name:     DuplicateElements
// keywords: check if duplicate elements are the same!
// status:   incorrect

model DuplicateElements
 Real x;
 Integer x;
end DuplicateElements;

// Result:
// Error processing file: DuplicateElements.mo
// [flattening/modelica/others/DuplicateElements.mo:7:2-7:11:writable] Notification: From here:
// [flattening/modelica/others/DuplicateElements.mo:6:2-6:8:writable] Error: Duplicate elements (due to inherited elements) not identical:
//   first element is:  Integer x
//   second element is: Real x
// Error: Error occurred while flattening model DuplicateElements
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
