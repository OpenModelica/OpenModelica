// name: InvalidExpandableConnector1
// keywords:
// status: incorrect
//


expandable connector EC
end EC;

connector C
  Real x;
end C;

model InvalidExpandableConnector1
  EC ec;
  C c;
equation
  connect(ec, c);
end InvalidExpandableConnector1;

// Result:
// Error processing file: InvalidExpandableConnector1.mo
// [flattening/modelica/expandable/InvalidExpandableConnector1.mo:16:3-16:6:writable] Warning: Connector c is not balanced: The number of potential variables (1) is not equal to the number of flow variables (0).
// [flattening/modelica/expandable/InvalidExpandableConnector1.mo:18:3-18:17:writable] Error: Cannot connect expandable connector ec with non-expandable connector c.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
