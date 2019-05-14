// name: ExpandableConnectorNonDecl4
// keywords: expandable connector
// status: incorrect
// cflags: -d=newInst
//
//

connector RealInput = input Real;

expandable connector EC
end EC;

model ExpandableConnectorNonDecl4
  RealInput ri;
equation
  connect(EC.ri, ri);
end ExpandableConnectorNonDecl4;

// Result:
// Error processing file: ExpandableConnectorNonDecl4.mo
// [flattening/modelica/scodeinst/ExpandableConnectorNonDecl4.mo:16:3-16:21:writable] Error: Variable EC.ri not found in scope ExpandableConnectorNonDecl4.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
