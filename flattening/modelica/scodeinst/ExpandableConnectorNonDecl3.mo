// name: ExpandableConnectorNonDecl3
// keywords: expandable connector
// status: incorrect
// cflags: -d=newInst
//
//

connector RealInput = input Real;

expandable connector EC
end EC;

model ExpandableConnectorNonDecl3
  RealInput ri;
  EC ec;
equation
  connect(ec.c.ri, ri);
end ExpandableConnectorNonDecl3;

// Result:
// Error processing file: ExpandableConnectorNonDecl3.mo
// [flattening/modelica/scodeinst/ExpandableConnectorNonDecl3.mo:17:3-17:23:writable] Error: Variable ec.c.ri not found in scope ExpandableConnectorNonDecl3.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
