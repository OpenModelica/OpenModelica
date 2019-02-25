// name: ExpandableConnectorNonDecl1
// keywords: expandable connector
// status: incorrect
// cflags: -d=newInst
//
//

expandable connector EC
end EC;

model ExpandableConnectorNonDecl1
  EC ec1, ec2;
equation
  connect(ec1.c, ec2.c);
end ExpandableConnectorNonDecl1;

// Result:
// Error processing file: ExpandableConnectorNonDecl1.mo
// [flattening/modelica/scodeinst/ExpandableConnectorNonDecl1.mo:14:3-14:24:writable] Error: Cannot connect undeclared connectors ec1.c with ec2.c. At least one of them must be declared.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
