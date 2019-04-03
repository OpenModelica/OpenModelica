// name:     DuplicateElementsEquivalent
// keywords: check if duplicate elements are the same even with when having named imports!
// status:   incorrect


package Crap
  type X = Real;
  type Y = Real;
end Crap;


model DuplicateElementsEquivalent
 import C=Crap;
 C.X x;
 Crap.X x;
end DuplicateElementsEquivalent;

// Result:
// Error processing file: DuplicateElementsEquivalent.mo
// [flattening/modelica/others/DuplicateElementsEquivalent.mo:15:2-15:10:writable] Error: An element with name x is already declared in this scope.
// Error: Error occurred while flattening model DuplicateElementsEquivalent
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
