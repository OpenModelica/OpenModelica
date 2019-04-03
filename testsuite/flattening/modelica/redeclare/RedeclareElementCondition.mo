// name:     RedeclareElementCondition
// keywords: 
// status:   incorrect
//

model A
  replaceable Real x = 1.0;
end A;

model RedeclareElementCondition
  extends A;

  redeclare Real x if false;
end RedeclareElementCondition;

// Result:
// Error processing file: RedeclareElementCondition.mo
// [flattening/modelica/redeclare/RedeclareElementCondition.mo:13:3-13:28:writable] Error: Invalid redeclaration of x, a redeclare may not have a condition attribute.
// Error: Error occurred while flattening model RedeclareElementCondition
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
