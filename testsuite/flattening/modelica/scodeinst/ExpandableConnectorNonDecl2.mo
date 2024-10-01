// name: ExpandableConnectorNonDecl2
// keywords: expandable connector
// status: incorrect
//
//

connector RealInput = input Real;

model ExpandableConnectorNonDecl2
  RealInput ri;
equation
  connect(ec.ri, ri);
end ExpandableConnectorNonDecl2;

// Result:
// Error processing file: ExpandableConnectorNonDecl2.mo
// [flattening/modelica/scodeinst/ExpandableConnectorNonDecl2.mo:12:3-12:21:writable] Error: Variable ec.ri not found in scope ExpandableConnectorNonDecl2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
