// name: redeclare6.mo
// keywords:
// status: incorrect
//


model A
  replaceable Integer x;
end A;

model B
  extends A(redeclare replaceable Integer x = 2);
end B;

model C
  extends B(redeclare Real x = 3);
end C;

// Result:
// Error processing file: redeclare6.mo
// [flattening/modelica/scodeinst/redeclare6.mo:16:13-16:33:writable] Notification: From here:
// [flattening/modelica/scodeinst/redeclare6.mo:8:3-8:24:writable] Error: Redeclaration of component 'x' is not a subtype of the redeclared element.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
