// name: AssignPackage1
// keywords:
// status: incorrect
//

package P
  constant Integer n = 2;
end P;

model AssignPackage1
  P p1, p2;
algorithm
  p1 := p2;
end AssignPackage1;

// Result:
// Error processing file: AssignPackage1.mo
// [flattening/modelica/scodeinst/AssignPackage1.mo:13:3-13:11:writable] Error: Component 'p1' may not be assigned to due to class specialization 'package'.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
