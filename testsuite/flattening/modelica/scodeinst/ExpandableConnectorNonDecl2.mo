// name: ExpandableConnectorNonDecl2
// keywords: expandable connector
// status: incorrect
// cflags: -d=newInst
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
// [flattening/modelica/scodeinst/ExpandableConnectorNonDecl2.mo:13:3-13:21:writable] Error: Variable ec.ri not found in scope ExpandableConnectorNonDecl2.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
