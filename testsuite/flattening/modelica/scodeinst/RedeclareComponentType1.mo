// name: RedeclareComponentType1
// keywords:
// status: incorrect
//
// Checks that a component of a basic type can't be redeclared with another
// basic type, see #1061.
//

model C1
  replaceable parameter Real r = 3.14;
end C1;

model RedeclareComponentType1
  C1 x1(redeclare replaceable Integer r = 3);
end RedeclareComponentType1;

// Result:
// Error processing file: RedeclareComponentType1.mo
// [flattening/modelica/scodeinst/RedeclareComponentType1.mo:14:19-14:44:writable] Notification: From here:
// [flattening/modelica/scodeinst/RedeclareComponentType1.mo:10:3-10:38:writable] Error: Redeclaration of component 'r' is not a subtype of the redeclared element.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
