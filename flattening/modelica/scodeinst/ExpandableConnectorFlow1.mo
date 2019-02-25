// name: ExpandableConnectorFlow1
// keywords: expandable connector
// status: incorrect
// cflags: -d=newInst
//
// Expandable connectors may not contain elements declared as flow.
//

expandable connector Bus
  flow Real f;
end Bus;

model ExpandableConnectorFlow1
  Bus bus;
end ExpandableConnectorFlow1;

// Result:
// Error processing file: ExpandableConnectorFlow1.mo
// [flattening/modelica/scodeinst/ExpandableConnectorFlow1.mo:10:3-10:14:writable] Error: Prefix ‘flow‘ on component ‘f‘ not allowed in class specialization ‘expandable connector‘.
//
// # Error encountered! Exiting...
// # Please check the error message and the flags.
//
// Execution failed!
// endResult
